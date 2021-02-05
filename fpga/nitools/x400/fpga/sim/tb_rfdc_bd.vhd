
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.PkgNiUtilities.all;
  use work.PkgNiSim.all;
  use work.PkgAxi4Lite.all;
  use work.PkgBusApi.all;

library std;
  use std.env.finish;

entity tb_rfdc_bd is
end tb_rfdc_bd;

architecture test of tb_rfdc_bd is

  component rfdc_imp_1SA090Q
    port (
      adc0_clk_clk_n                : in  STD_LOGIC;
      adc0_clk_clk_p                : in  STD_LOGIC;
      adc2_clk_clk_n                : in  STD_LOGIC;
      adc2_clk_clk_p                : in  STD_LOGIC;
      adc_tile224_axis_resetn_rclk  : in  STD_LOGIC;
      adc_tile224_ch0_dout_i_tdata  : out STD_LOGIC_VECTOR(127 downto 0);
      adc_tile224_ch0_dout_i_tready : in  STD_LOGIC;
      adc_tile224_ch0_dout_i_tvalid : out STD_LOGIC;
      adc_tile224_ch0_dout_q_tdata  : out STD_LOGIC_VECTOR(127 downto 0);
      adc_tile224_ch0_dout_q_tready : in  STD_LOGIC;
      adc_tile224_ch0_dout_q_tvalid : out STD_LOGIC;
      adc_tile224_ch0_vin_v_n       : in  STD_LOGIC;
      adc_tile224_ch0_vin_v_p       : in  STD_LOGIC;
      adc_tile224_ch1_dout_i_tdata  : out STD_LOGIC_VECTOR(127 downto 0);
      adc_tile224_ch1_dout_i_tready : in  STD_LOGIC;
      adc_tile224_ch1_dout_i_tvalid : out STD_LOGIC;
      adc_tile224_ch1_dout_q_tdata  : out STD_LOGIC_VECTOR(127 downto 0);
      adc_tile224_ch1_dout_q_tready : in  STD_LOGIC;
      adc_tile224_ch1_dout_q_tvalid : out STD_LOGIC;
      adc_tile224_ch1_vin_v_n       : in  STD_LOGIC;
      adc_tile224_ch1_vin_v_p       : in  STD_LOGIC;
      adc_tile226_axis_resetn_rclk  : in  STD_LOGIC;
      adc_tile226_ch0_dout_i_tdata  : out STD_LOGIC_VECTOR(127 downto 0);
      adc_tile226_ch0_dout_i_tready : in  STD_LOGIC;
      adc_tile226_ch0_dout_i_tvalid : out STD_LOGIC;
      adc_tile226_ch0_dout_q_tdata  : out STD_LOGIC_VECTOR(127 downto 0);
      adc_tile226_ch0_dout_q_tready : in  STD_LOGIC;
      adc_tile226_ch0_dout_q_tvalid : out STD_LOGIC;
      adc_tile226_ch0_vin_v_n       : in  STD_LOGIC;
      adc_tile226_ch0_vin_v_p       : in  STD_LOGIC;
      adc_tile226_ch1_dout_i_tdata  : out STD_LOGIC_VECTOR(127 downto 0);
      adc_tile226_ch1_dout_i_tready : in  STD_LOGIC;
      adc_tile226_ch1_dout_i_tvalid : out STD_LOGIC;
      adc_tile226_ch1_dout_q_tdata  : out STD_LOGIC_VECTOR(127 downto 0);
      adc_tile226_ch1_dout_q_tready : in  STD_LOGIC;
      adc_tile226_ch1_dout_q_tvalid : out STD_LOGIC;
      adc_tile226_ch1_vin_v_n       : in  STD_LOGIC;
      adc_tile226_ch1_vin_v_p       : in  STD_LOGIC;
      dac0_clk_clk_n                : in  STD_LOGIC;
      dac0_clk_clk_p                : in  STD_LOGIC;
      dac1_clk_clk_n                : in  STD_LOGIC;
      dac1_clk_clk_p                : in  STD_LOGIC;
      dac_tile228_axis_resetn_rclk  : in  STD_LOGIC;
      dac_tile228_ch0_din_tdata     : in  STD_LOGIC_VECTOR(255 downto 0);
      dac_tile228_ch0_din_tready    : out STD_LOGIC;
      dac_tile228_ch0_din_tvalid    : in  STD_LOGIC;
      dac_tile228_ch0_vout_v_n      : out STD_LOGIC;
      dac_tile228_ch0_vout_v_p      : out STD_LOGIC;
      dac_tile228_ch1_din_tdata     : in  STD_LOGIC_VECTOR(255 downto 0);
      dac_tile228_ch1_din_tready    : out STD_LOGIC;
      dac_tile228_ch1_din_tvalid    : in  STD_LOGIC;
      dac_tile228_ch1_vout_v_n      : out STD_LOGIC;
      dac_tile228_ch1_vout_v_p      : out STD_LOGIC;
      dac_tile229_axis_resetn_rclk  : in  STD_LOGIC;
      dac_tile229_ch0_din_tdata     : in  STD_LOGIC_VECTOR(255 downto 0);
      dac_tile229_ch0_din_tready    : out STD_LOGIC;
      dac_tile229_ch0_din_tvalid    : in  STD_LOGIC;
      dac_tile229_ch0_vout_v_n      : out STD_LOGIC;
      dac_tile229_ch0_vout_v_p      : out STD_LOGIC;
      dac_tile229_ch1_din_tdata     : in  STD_LOGIC_VECTOR(255 downto 0);
      dac_tile229_ch1_din_tready    : out STD_LOGIC;
      dac_tile229_ch1_din_tvalid    : in  STD_LOGIC;
      dac_tile229_ch1_vout_v_n      : out STD_LOGIC;
      dac_tile229_ch1_vout_v_p      : out STD_LOGIC;
      data_clk                      : out STD_LOGIC;
      data_clk_2x                   : out STD_LOGIC;
      data_clock_locked             : out STD_LOGIC;
      enable_sysref_rclk            : in  STD_LOGIC;
      invert_adc_iq_rclk2           : out STD_LOGIC_VECTOR(7 downto 0);
      invert_dac_iq_rclk2           : out STD_LOGIC_VECTOR(7 downto 0);
      pll_ref_clk_in                : in  STD_LOGIC;
      pll_ref_clk_out               : out STD_LOGIC;
      rf_axi_status_sclk            : in  STD_LOGIC_VECTOR(31 downto 0);
      rf_dsp_info_sclk              : in  STD_LOGIC_VECTOR(31 downto 0);
      rf_reset_control_sclk         : out STD_LOGIC_VECTOR(31 downto 0);
      rf_reset_status_sclk          : in  STD_LOGIC_VECTOR(31 downto 0);
      rfdc_clk                      : out STD_LOGIC;
      rfdc_clk_2x                   : out STD_LOGIC;
      rfdc_irq                      : out STD_LOGIC;
      s_axi_config_araddr           : in  STD_LOGIC_VECTOR(39 downto 0);
      s_axi_config_aresetn          : in  STD_LOGIC;
      s_axi_config_arprot           : in  STD_LOGIC_VECTOR(2 downto 0);
      s_axi_config_arready          : out STD_LOGIC_VECTOR(0 to 0);
      s_axi_config_arvalid          : in  STD_LOGIC_VECTOR(0 to 0);
      s_axi_config_awaddr           : in  STD_LOGIC_VECTOR(39 downto 0);
      s_axi_config_awprot           : in  STD_LOGIC_VECTOR(2 downto 0);
      s_axi_config_awready          : out STD_LOGIC_VECTOR(0 to 0);
      s_axi_config_awvalid          : in  STD_LOGIC_VECTOR(0 to 0);
      s_axi_config_bready           : in  STD_LOGIC_VECTOR(0 to 0);
      s_axi_config_bresp            : out STD_LOGIC_VECTOR(1 downto 0);
      s_axi_config_bvalid           : out STD_LOGIC_VECTOR(0 to 0);
      s_axi_config_clk              : in  STD_LOGIC;
      s_axi_config_rdata            : out STD_LOGIC_VECTOR(31 downto 0);
      s_axi_config_rready           : in  STD_LOGIC_VECTOR(0 to 0);
      s_axi_config_rresp            : out STD_LOGIC_VECTOR(1 downto 0);
      s_axi_config_rvalid           : out STD_LOGIC_VECTOR(0 to 0);
      s_axi_config_wdata            : in  STD_LOGIC_VECTOR(31 downto 0);
      s_axi_config_wready           : out STD_LOGIC_VECTOR(0 to 0);
      s_axi_config_wstrb            : in  STD_LOGIC_VECTOR(3 downto 0);
      s_axi_config_wvalid           : in  STD_LOGIC_VECTOR(0 to 0);
      sysref_out_pclk               : out STD_LOGIC;
      sysref_out_rclk               : out STD_LOGIC;
      sysref_pl_in                  : in  STD_LOGIC;
      sysref_rf_in_diff_n           : in  STD_LOGIC;
      sysref_rf_in_diff_p           : in  STD_LOGIC);
  end component;

  --vhook_nowarn tb_rfdc_bd.test.capture_sysref
  --vhook_d capture_sysref
  component capture_sysref
    port (
      pll_ref_clk     : in  std_logic;
      rfdc_clk        : in  std_logic;
      sysref_in       : in  std_logic;
      enable_rclk     : in  std_logic;
      sysref_out_pclk : out std_logic;
      sysref_out_rclk : out std_logic);
  end component;

--NISIM comments for loading simulation. Note that glbl is not an option, but actually
--  a verilog file that is loaded next to the testbench. Keeping it as the last option
--  will work
  -- --o="-L xpm -L unisims_ver -L secureip -L unimacro_ver glbl"

  --nisim --PreLoadCmd="source vsim_ops_x4xx_ps_rfdc_bd.tcl"
  --nisim --op1="{*}$vsimOps"

  --glbl.v is a Xilinx file that needs to be compiled into the work library and loaded
  -- with the simulation. To make this process automatic, the file is added to the
  -- vsmake settings search path, the loading is added to the nisim options and
  -- a component for it is declared here to force vsmake to compile it. The nowarn
  -- exception will remove the linting message complaining about the unused component.

  --vhook_nowarn msg={Component '.*glbl' has no references}
  -- vhook_d glbl
  -- component glbl
    -- generic (
      -- ROC_WIDTH : integer := 100000;
      -- TOC_WIDTH : integer := 0);
  -- end component;

  --vhook_sigstart
  signal adc_rfdc_axi_resetn_rclk: STD_LOGIC := '0';
  signal adc_tile224_ch0_dout_i_tdata: STD_LOGIC_VECTOR(127 downto 0);
  signal adc_tile224_ch0_dout_i_tvalid: STD_LOGIC;
  signal adc_tile224_ch0_dout_q_tdata: STD_LOGIC_VECTOR(127 downto 0);
  signal adc_tile224_ch0_dout_q_tvalid: STD_LOGIC;
  signal adc_tile224_ch0_vin_v_n: STD_LOGIC;
  signal adc_tile224_ch0_vin_v_p: STD_LOGIC;
  signal adc_tile224_ch1_dout_i_tdata: STD_LOGIC_VECTOR(127 downto 0);
  signal adc_tile224_ch1_dout_i_tvalid: STD_LOGIC;
  signal adc_tile224_ch1_dout_q_tdata: STD_LOGIC_VECTOR(127 downto 0);
  signal adc_tile224_ch1_dout_q_tvalid: STD_LOGIC;
  signal adc_tile224_ch1_vin_v_n: STD_LOGIC;
  signal adc_tile224_ch1_vin_v_p: STD_LOGIC;
  signal adc_tile226_ch0_dout_i_tdata: STD_LOGIC_VECTOR(127 downto 0);
  signal adc_tile226_ch0_dout_i_tvalid: STD_LOGIC;
  signal adc_tile226_ch0_dout_q_tdata: STD_LOGIC_VECTOR(127 downto 0);
  signal adc_tile226_ch0_dout_q_tvalid: STD_LOGIC;
  signal adc_tile226_ch0_vin_v_n: STD_LOGIC;
  signal adc_tile226_ch0_vin_v_p: STD_LOGIC;
  signal adc_tile226_ch1_dout_i_tdata: STD_LOGIC_VECTOR(127 downto 0);
  signal adc_tile226_ch1_dout_i_tvalid: STD_LOGIC;
  signal adc_tile226_ch1_dout_q_tdata: STD_LOGIC_VECTOR(127 downto 0);
  signal adc_tile226_ch1_dout_q_tvalid: STD_LOGIC;
  signal adc_tile226_ch1_vin_v_n: STD_LOGIC;
  signal adc_tile226_ch1_vin_v_p: STD_LOGIC;
  signal dac0_clk_clk_n: STD_LOGIC := '1';
  signal dac0_clk_clk_p: STD_LOGIC := '0';
  signal dac1_clk_clk_n: STD_LOGIC := '1';
  signal dac1_clk_clk_p: STD_LOGIC := '0';
  signal dac_rfdc_axi_resetn_rclk: STD_LOGIC := '0';
  signal dac_tile228_ch0_din_tdata: STD_LOGIC_VECTOR(255 downto 0);
  signal dac_tile228_ch0_din_tready: STD_LOGIC;
  signal dac_tile228_ch0_din_tvalid: STD_LOGIC;
  signal dac_tile228_ch0_vout_v_n: STD_LOGIC;
  signal dac_tile228_ch0_vout_v_p: STD_LOGIC;
  signal dac_tile228_ch1_din_tdata: STD_LOGIC_VECTOR(255 downto 0);
  signal dac_tile228_ch1_din_tready: STD_LOGIC;
  signal dac_tile228_ch1_din_tvalid: STD_LOGIC;
  signal dac_tile228_ch1_vout_v_n: STD_LOGIC;
  signal dac_tile228_ch1_vout_v_p: STD_LOGIC;
  signal dac_tile229_ch0_din_tdata: STD_LOGIC_VECTOR(255 downto 0);
  signal dac_tile229_ch0_din_tready: STD_LOGIC;
  signal dac_tile229_ch0_din_tvalid: STD_LOGIC;
  signal dac_tile229_ch0_vout_v_n: STD_LOGIC;
  signal dac_tile229_ch0_vout_v_p: STD_LOGIC;
  signal dac_tile229_ch1_din_tdata: STD_LOGIC_VECTOR(255 downto 0);
  signal dac_tile229_ch1_din_tready: STD_LOGIC;
  signal dac_tile229_ch1_din_tvalid: STD_LOGIC;
  signal dac_tile229_ch1_vout_v_n: STD_LOGIC;
  signal dac_tile229_ch1_vout_v_p: STD_LOGIC;
  signal data_clk: STD_LOGIC := '0';
  signal data_clk_2x: STD_LOGIC := '0';
  signal data_clock_locked: STD_LOGIC := '0';
  signal enable_sysref_rclk: STD_LOGIC := '0';
  signal invert_adc_iq_rclk2: STD_LOGIC_VECTOR(7 downto 0);
  signal invert_dac_iq_rclk2: STD_LOGIC_VECTOR(7 downto 0);
  signal pll_ref_clk_out: STD_LOGIC := '0';
  signal rf_axi_status_sclk: STD_LOGIC_VECTOR(31 downto 0);
  signal rf_dsp_info_sclk: STD_LOGIC_VECTOR(31 downto 0);
  signal rf_reset_control_sclk: STD_LOGIC_VECTOR(31 downto 0);
  signal rf_reset_status_sclk: STD_LOGIC_VECTOR(31 downto 0);
  signal rfdc_clk: STD_LOGIC := '0';
  signal rfdc_clk_2x: STD_LOGIC := '0';
  signal rfdc_irq: STD_LOGIC;
  signal s_axi_config_araddr: STD_LOGIC_VECTOR(39 downto 0);
  signal s_axi_config_aresetn: STD_LOGIC;
  signal s_axi_config_arvalid: STD_LOGIC_VECTOR(0 to 0);
  signal s_axi_config_awaddr: STD_LOGIC_VECTOR(39 downto 0);
  signal s_axi_config_awvalid: STD_LOGIC_VECTOR(0 to 0);
  signal s_axi_config_bready: STD_LOGIC_VECTOR(0 to 0);
  signal s_axi_config_bresp: STD_LOGIC_VECTOR(1 downto 0);
  signal s_axi_config_bvalid: STD_LOGIC_VECTOR(0 to 0);
  signal s_axi_config_clk: std_logic := '0';
  signal s_axi_config_rdata: STD_LOGIC_VECTOR(31 downto 0);
  signal s_axi_config_rready: STD_LOGIC_VECTOR(0 to 0);
  signal s_axi_config_rresp: STD_LOGIC_VECTOR(1 downto 0);
  signal s_axi_config_rvalid: STD_LOGIC_VECTOR(0 to 0);
  signal s_axi_config_wvalid: STD_LOGIC_VECTOR(0 to 0);
  signal sysref_out_pclk: STD_LOGIC := '0';
  signal sysref_out_rclk: STD_LOGIC := '0';
  signal sysref_rf_in_diff_n: STD_LOGIC;
  signal sysref_rf_in_diff_p: STD_LOGIC;
  signal xAxiReadAddressChannel: Axi4LiteAddressChannel_t;
  signal xAxiReadAddressReadySl: STD_LOGIC_VECTOR(0 to 0);
  signal xAxiReadDataChannel: Axi4LiteReadDataChannel_t;
  signal xAxiReadDataReady: boolean;
  signal xAxiWriteAddressChannel: Axi4LiteAddressChannel_t;
  signal xAxiWriteAddressReadySl: STD_LOGIC_VECTOR(0 to 0);
  signal xAxiWriteDataChannel: Axi4LiteWriteDataChannel_t;
  signal xAxiWriteDataReadySl: STD_LOGIC_VECTOR(0 to 0);
  signal xAxiWriteResponseChannel: Axi4LiteWriteResponseChannel_t;
  signal xAxiWriteResponseReady: boolean;
  --vhook_sigend

  signal s_axi_config_arprot: std_logic_vector(2 downto 0) := (others => '0');
  signal s_axi_config_awprot: std_logic_vector(2 downto 0) := (others => '0');
  signal StopSim : boolean := false;
  signal rst : boolean := false;
  signal TestStatus : TestStatusString_t := (others => ' ');
  signal SampleClock : std_logic := '1';
  signal PllRefClock : std_logic := '1';
  signal sysref_pl_in: std_logic := '1';

  constant kConfigClockPeriod : time := 25 ns;   --AXI-Lite control runs at 40 MHz
  constant kSampleClockPeriod : time := 334 ps;  --since this is /2 we need an even number, ~3GHz
  constant kPllRefClockDivider : natural := 48;  --RefClk is ~62.5MHz
  constant kSysRefDivider : natural := 8;        --SysRef is ~7.8125MHz

begin

  VPrint(TestStatus);

  SampleClock <= not SampleClock after kSampleClockPeriod/2                                    when not StopSim else '0';
  PllRefClock <= not PllRefClock after kPllRefClockDivider*kSampleClockPeriod/2                when not StopSim else '0';
  sysref_pl_in   <= not sysref_pl_in   after kSysRefDivider*kPllRefClockDivider*kSampleClockPeriod/2 when not StopSim else '0';
  sysref_rf_in_diff_p <= not sysref_pl_in   after kSysRefDivider*kPllRefClockDivider*kSampleClockPeriod/2 when not StopSim else '0';
  sysref_rf_in_diff_n <=     sysref_pl_in   after kSysRefDivider*kPllRefClockDivider*kSampleClockPeriod/2 when not StopSim else '0';

  s_axi_config_clk <= not s_axi_config_clk after kConfigClockPeriod/2 when not StopSim else '0';

  s_axi_config_aresetn <= '0' when rst else '1' when rising_edge(s_axi_config_clk);
  adc_rfdc_axi_resetn_rclk <= '0' when rst else '1' when rising_edge(rfdc_clk);
  --vhook_warn TODO: DAC AXI stream hold in reset
  adc_rfdc_axi_resetn_rclk <= '1';
  -- adc_gearbox_reset_n_rclk2 <= '0' when rst else '1' when rising_edge(rfib_clk_2x);
  -- fir_resetn_rclk2 <= '0' when rst else '1' when rising_edge(rfib_clk_2x);

  --vhook_warn TODO: Make AXI-Lite address 40-bit, for now using constant offset for 8 MSBs
  s_axi_config_awaddr <= x"10" & std_logic_vector(xAxiWriteAddressChannel.Addr);
  s_axi_config_araddr <= x"10" & std_logic_vector(xAxiReadAddressChannel.Addr);

  --vhook_warn NOTE: simulating BD hierarchy only, entity name varies each compilation
  --vhook rfdc_imp_1SA090Q
  --vhook_a adc*_clk_clk_p                SampleClock
  --vhook_a adc*_clk_clk_n                not SampleClock
  --vhook_a {(.*)_(.*)_axis_resetn_rclk}  $1_rfdc_axi_resetn_rclk
  --vhook_a pll_ref_clk_in                PllRefClock
  --vhook_a adc_*_dout_*_tready           '1'
  --vhook_a s_axi_config_awready xAxiWriteAddressReadySl
  --vhook_a s_axi_config_wdata   xAxiWriteDataChannel.Data
  --vhook_a s_axi_config_wstrb   xAxiWriteDataChannel.Strb
  --vhook_a s_axi_config_wready  xAxiWriteDataReadySl
  --vhook_a s_axi_config_arready xAxiReadAddressReadySl
  rfdc_imp_1SA090Qx: rfdc_imp_1SA090Q
    port map (
      adc0_clk_clk_n                => not SampleClock,                --in  STD_LOGIC
      adc0_clk_clk_p                => SampleClock,                    --in  STD_LOGIC
      adc2_clk_clk_n                => not SampleClock,                --in  STD_LOGIC
      adc2_clk_clk_p                => SampleClock,                    --in  STD_LOGIC
      adc_tile224_axis_resetn_rclk  => adc_rfdc_axi_resetn_rclk,       --in  STD_LOGIC
      adc_tile224_ch0_dout_i_tdata  => adc_tile224_ch0_dout_i_tdata,   --out STD_LOGIC_VECTOR(127:0)
      adc_tile224_ch0_dout_i_tready => '1',                            --in  STD_LOGIC
      adc_tile224_ch0_dout_i_tvalid => adc_tile224_ch0_dout_i_tvalid,  --out STD_LOGIC
      adc_tile224_ch0_dout_q_tdata  => adc_tile224_ch0_dout_q_tdata,   --out STD_LOGIC_VECTOR(127:0)
      adc_tile224_ch0_dout_q_tready => '1',                            --in  STD_LOGIC
      adc_tile224_ch0_dout_q_tvalid => adc_tile224_ch0_dout_q_tvalid,  --out STD_LOGIC
      adc_tile224_ch0_vin_v_n       => adc_tile224_ch0_vin_v_n,        --in  STD_LOGIC
      adc_tile224_ch0_vin_v_p       => adc_tile224_ch0_vin_v_p,        --in  STD_LOGIC
      adc_tile224_ch1_dout_i_tdata  => adc_tile224_ch1_dout_i_tdata,   --out STD_LOGIC_VECTOR(127:0)
      adc_tile224_ch1_dout_i_tready => '1',                            --in  STD_LOGIC
      adc_tile224_ch1_dout_i_tvalid => adc_tile224_ch1_dout_i_tvalid,  --out STD_LOGIC
      adc_tile224_ch1_dout_q_tdata  => adc_tile224_ch1_dout_q_tdata,   --out STD_LOGIC_VECTOR(127:0)
      adc_tile224_ch1_dout_q_tready => '1',                            --in  STD_LOGIC
      adc_tile224_ch1_dout_q_tvalid => adc_tile224_ch1_dout_q_tvalid,  --out STD_LOGIC
      adc_tile224_ch1_vin_v_n       => adc_tile224_ch1_vin_v_n,        --in  STD_LOGIC
      adc_tile224_ch1_vin_v_p       => adc_tile224_ch1_vin_v_p,        --in  STD_LOGIC
      adc_tile226_axis_resetn_rclk  => adc_rfdc_axi_resetn_rclk,       --in  STD_LOGIC
      adc_tile226_ch0_dout_i_tdata  => adc_tile226_ch0_dout_i_tdata,   --out STD_LOGIC_VECTOR(127:0)
      adc_tile226_ch0_dout_i_tready => '1',                            --in  STD_LOGIC
      adc_tile226_ch0_dout_i_tvalid => adc_tile226_ch0_dout_i_tvalid,  --out STD_LOGIC
      adc_tile226_ch0_dout_q_tdata  => adc_tile226_ch0_dout_q_tdata,   --out STD_LOGIC_VECTOR(127:0)
      adc_tile226_ch0_dout_q_tready => '1',                            --in  STD_LOGIC
      adc_tile226_ch0_dout_q_tvalid => adc_tile226_ch0_dout_q_tvalid,  --out STD_LOGIC
      adc_tile226_ch0_vin_v_n       => adc_tile226_ch0_vin_v_n,        --in  STD_LOGIC
      adc_tile226_ch0_vin_v_p       => adc_tile226_ch0_vin_v_p,        --in  STD_LOGIC
      adc_tile226_ch1_dout_i_tdata  => adc_tile226_ch1_dout_i_tdata,   --out STD_LOGIC_VECTOR(127:0)
      adc_tile226_ch1_dout_i_tready => '1',                            --in  STD_LOGIC
      adc_tile226_ch1_dout_i_tvalid => adc_tile226_ch1_dout_i_tvalid,  --out STD_LOGIC
      adc_tile226_ch1_dout_q_tdata  => adc_tile226_ch1_dout_q_tdata,   --out STD_LOGIC_VECTOR(127:0)
      adc_tile226_ch1_dout_q_tready => '1',                            --in  STD_LOGIC
      adc_tile226_ch1_dout_q_tvalid => adc_tile226_ch1_dout_q_tvalid,  --out STD_LOGIC
      adc_tile226_ch1_vin_v_n       => adc_tile226_ch1_vin_v_n,        --in  STD_LOGIC
      adc_tile226_ch1_vin_v_p       => adc_tile226_ch1_vin_v_p,        --in  STD_LOGIC
      dac0_clk_clk_n                => dac0_clk_clk_n,                 --in  STD_LOGIC
      dac0_clk_clk_p                => dac0_clk_clk_p,                 --in  STD_LOGIC
      dac1_clk_clk_n                => dac1_clk_clk_n,                 --in  STD_LOGIC
      dac1_clk_clk_p                => dac1_clk_clk_p,                 --in  STD_LOGIC
      dac_tile228_axis_resetn_rclk  => dac_rfdc_axi_resetn_rclk,       --in  STD_LOGIC
      dac_tile228_ch0_din_tdata     => dac_tile228_ch0_din_tdata,      --in  STD_LOGIC_VECTOR(255:0)
      dac_tile228_ch0_din_tready    => dac_tile228_ch0_din_tready,     --out STD_LOGIC
      dac_tile228_ch0_din_tvalid    => dac_tile228_ch0_din_tvalid,     --in  STD_LOGIC
      dac_tile228_ch0_vout_v_n      => dac_tile228_ch0_vout_v_n,       --out STD_LOGIC
      dac_tile228_ch0_vout_v_p      => dac_tile228_ch0_vout_v_p,       --out STD_LOGIC
      dac_tile228_ch1_din_tdata     => dac_tile228_ch1_din_tdata,      --in  STD_LOGIC_VECTOR(255:0)
      dac_tile228_ch1_din_tready    => dac_tile228_ch1_din_tready,     --out STD_LOGIC
      dac_tile228_ch1_din_tvalid    => dac_tile228_ch1_din_tvalid,     --in  STD_LOGIC
      dac_tile228_ch1_vout_v_n      => dac_tile228_ch1_vout_v_n,       --out STD_LOGIC
      dac_tile228_ch1_vout_v_p      => dac_tile228_ch1_vout_v_p,       --out STD_LOGIC
      dac_tile229_axis_resetn_rclk  => dac_rfdc_axi_resetn_rclk,       --in  STD_LOGIC
      dac_tile229_ch0_din_tdata     => dac_tile229_ch0_din_tdata,      --in  STD_LOGIC_VECTOR(255:0)
      dac_tile229_ch0_din_tready    => dac_tile229_ch0_din_tready,     --out STD_LOGIC
      dac_tile229_ch0_din_tvalid    => dac_tile229_ch0_din_tvalid,     --in  STD_LOGIC
      dac_tile229_ch0_vout_v_n      => dac_tile229_ch0_vout_v_n,       --out STD_LOGIC
      dac_tile229_ch0_vout_v_p      => dac_tile229_ch0_vout_v_p,       --out STD_LOGIC
      dac_tile229_ch1_din_tdata     => dac_tile229_ch1_din_tdata,      --in  STD_LOGIC_VECTOR(255:0)
      dac_tile229_ch1_din_tready    => dac_tile229_ch1_din_tready,     --out STD_LOGIC
      dac_tile229_ch1_din_tvalid    => dac_tile229_ch1_din_tvalid,     --in  STD_LOGIC
      dac_tile229_ch1_vout_v_n      => dac_tile229_ch1_vout_v_n,       --out STD_LOGIC
      dac_tile229_ch1_vout_v_p      => dac_tile229_ch1_vout_v_p,       --out STD_LOGIC
      data_clk                      => data_clk,                       --out STD_LOGIC
      data_clk_2x                   => data_clk_2x,                    --out STD_LOGIC
      data_clock_locked             => data_clock_locked,              --out STD_LOGIC
      enable_sysref_rclk            => enable_sysref_rclk,             --in  STD_LOGIC
      invert_adc_iq_rclk2           => invert_adc_iq_rclk2,            --out STD_LOGIC_VECTOR(7:0)
      invert_dac_iq_rclk2           => invert_dac_iq_rclk2,            --out STD_LOGIC_VECTOR(7:0)
      pll_ref_clk_in                => PllRefClock,                    --in  STD_LOGIC
      pll_ref_clk_out               => pll_ref_clk_out,                --out STD_LOGIC
      rf_axi_status_sclk            => rf_axi_status_sclk,             --in  STD_LOGIC_VECTOR(31:0)
      rf_dsp_info_sclk              => rf_dsp_info_sclk,               --in  STD_LOGIC_VECTOR(31:0)
      rf_reset_control_sclk         => rf_reset_control_sclk,          --out STD_LOGIC_VECTOR(31:0)
      rf_reset_status_sclk          => rf_reset_status_sclk,           --in  STD_LOGIC_VECTOR(31:0)
      rfdc_clk                      => rfdc_clk,                       --out STD_LOGIC
      rfdc_clk_2x                   => rfdc_clk_2x,                    --out STD_LOGIC
      rfdc_irq                      => rfdc_irq,                       --out STD_LOGIC
      s_axi_config_araddr           => s_axi_config_araddr,            --in  STD_LOGIC_VECTOR(39:0)
      s_axi_config_aresetn          => s_axi_config_aresetn,           --in  STD_LOGIC
      s_axi_config_arprot           => s_axi_config_arprot,            --in  STD_LOGIC_VECTOR(2:0)
      s_axi_config_arready          => xAxiReadAddressReadySl,         --out STD_LOGIC_VECTOR(0:0)
      s_axi_config_arvalid          => s_axi_config_arvalid,           --in  STD_LOGIC_VECTOR(0:0)
      s_axi_config_awaddr           => s_axi_config_awaddr,            --in  STD_LOGIC_VECTOR(39:0)
      s_axi_config_awprot           => s_axi_config_awprot,            --in  STD_LOGIC_VECTOR(2:0)
      s_axi_config_awready          => xAxiWriteAddressReadySl,        --out STD_LOGIC_VECTOR(0:0)
      s_axi_config_awvalid          => s_axi_config_awvalid,           --in  STD_LOGIC_VECTOR(0:0)
      s_axi_config_bready           => s_axi_config_bready,            --in  STD_LOGIC_VECTOR(0:0)
      s_axi_config_bresp            => s_axi_config_bresp,             --out STD_LOGIC_VECTOR(1:0)
      s_axi_config_bvalid           => s_axi_config_bvalid,            --out STD_LOGIC_VECTOR(0:0)
      s_axi_config_clk              => s_axi_config_clk,               --in  STD_LOGIC
      s_axi_config_rdata            => s_axi_config_rdata,             --out STD_LOGIC_VECTOR(31:0)
      s_axi_config_rready           => s_axi_config_rready,            --in  STD_LOGIC_VECTOR(0:0)
      s_axi_config_rresp            => s_axi_config_rresp,             --out STD_LOGIC_VECTOR(1:0)
      s_axi_config_rvalid           => s_axi_config_rvalid,            --out STD_LOGIC_VECTOR(0:0)
      s_axi_config_wdata            => xAxiWriteDataChannel.Data,      --in  STD_LOGIC_VECTOR(31:0)
      s_axi_config_wready           => xAxiWriteDataReadySl,           --out STD_LOGIC_VECTOR(0:0)
      s_axi_config_wstrb            => xAxiWriteDataChannel.Strb,      --in  STD_LOGIC_VECTOR(3:0)
      s_axi_config_wvalid           => s_axi_config_wvalid,            --in  STD_LOGIC_VECTOR(0:0)
      sysref_out_pclk               => sysref_out_pclk,                --out STD_LOGIC
      sysref_out_rclk               => sysref_out_rclk,                --out STD_LOGIC
      sysref_pl_in                  => sysref_pl_in,                   --in  STD_LOGIC
      sysref_rf_in_diff_n           => sysref_rf_in_diff_n,            --in  STD_LOGIC
      sysref_rf_in_diff_p           => sysref_rf_in_diff_p);           --in  STD_LOGIC


  s_axi_config_wvalid(0) <= to_StdLogic(xAxiWriteDataChannel.Valid);
  s_axi_config_awvalid(0) <= to_StdLogic(xAxiWriteAddressChannel.Valid);
  s_axi_config_arvalid(0) <= to_StdLogic(xAxiReadAddressChannel.Valid);
  s_axi_config_rready(0) <= to_StdLogic(xAxiReadDataReady);
  s_axi_config_bready(0) <= to_StdLogic(xAxiWriteResponseReady);

  --vhook_nowarn id=CP14 tb_rfdc_bd.test.xAxiReadDataReady
  --vhook_nowarn id=CP14 tb_rfdc_bd.test.xAxiWriteResponseReady
  --vcheck is incorrectly detecting these as unread

  xAxiWriteResponseChannel.Resp <= s_axi_config_bresp;
  xAxiWriteResponseChannel.Valid <= to_Boolean(s_axi_config_bvalid(0));
  xAxiReadDataChannel.Data <= s_axi_config_rdata;
  xAxiReadDataChannel.Resp <= s_axi_config_rresp;
  xAxiReadDataChannel.Valid <= to_Boolean(s_axi_config_rvalid(0));

  --vhook_e MbAxi4LiteBfm
  --vhook_c kBfmInstance 0
  --vhook_a Clock s_axi_config_clk
  --vhook_a cAxiWriteAddressReady to_Boolean(xAxiWriteAddressReadySl(0))
  --vhook_a cAxiWriteDataReady to_Boolean(xAxiWriteDataReadySl(0))
  --vhook_a cAxiReadAddressReady to_Boolean(xAxiReadAddressReadySl(0))
  --vhook_a {c(.*)} x$1
  --vhook_a RegStat open
  MbAxi4LiteBfmx: entity work.MbAxi4LiteBfm (model)
    generic map (kBfmInstance => 0)  --natural:=0
    port map (
      Clock                    => s_axi_config_clk,                        --in  std_logic
      cAxiWriteAddressChannel  => xAxiWriteAddressChannel,                 --out Axi4LiteAddressChannel_t
      cAxiWriteAddressReady    => to_Boolean(xAxiWriteAddressReadySl(0)),  --in  boolean
      cAxiWriteDataChannel     => xAxiWriteDataChannel,                    --out Axi4LiteWriteDataChannel_t
      cAxiWriteDataReady       => to_Boolean(xAxiWriteDataReadySl(0)),     --in  boolean
      cAxiWriteResponseChannel => xAxiWriteResponseChannel,                --in  Axi4LiteWriteResponseChannel_t
      cAxiWriteResponseReady   => xAxiWriteResponseReady,                  --out boolean
      cAxiReadAddressChannel   => xAxiReadAddressChannel,                  --out Axi4LiteAddressChannel_t
      cAxiReadAddressReady     => to_Boolean(xAxiReadAddressReadySl(0)),   --in  boolean
      cAxiReadDataChannel      => xAxiReadDataChannel,                     --in  Axi4LiteReadDataChannel_t
      cAxiReadDataReady        => xAxiReadDataReady,                       --out boolean
      RegStat                  => open);                                   --out TestStatusString_t

  --vhook_warn hook up data model
  adc_tile224_ch0_vin_v_n <= '0';
  adc_tile224_ch0_vin_v_p <= '1';
  adc_tile224_ch1_vin_v_n <= '0';
  adc_tile224_ch1_vin_v_p <= '1';
  adc_tile226_ch0_vin_v_n <= '0';
  adc_tile226_ch0_vin_v_p <= '1';
  adc_tile226_ch1_vin_v_n <= '0';
  adc_tile226_ch1_vin_v_p <= '1';



  DriverProcess: process
    variable PioData : std_logic_vector(31 downto 0);
    procedure ResetAndLockMmcm is
    begin
      VPrint("Time: " & ImageUS(now));
      VPrint("Deassert MMCM's AXI Reset...");
      PioData := (others => '0');
      PioData(3 downto 0) := x"1";
      BusWt(16#15_1000#, PioData);
      VPrint("Asserting Data Clock MMCM Reset...");
      PioData := (others => '0');
      PioData(3 downto 0) := x"A";
      BusWt(16#14_0000#, PioData);
      assert data_clock_locked = '0'
        report "Data Clock MMCM did not unlock after reset!"
        severity error;
      wait until data_clock_locked = '1' for 10 us;
      assert data_clock_locked = '1'
        report "Data Clock MMCM did not lock within 10 us!"
        severity error;
      VPrint("Reading locked bit...");
      BusRd(16#14_0004#, PioData);
      VPrint("Locked Register (0x04): " & HexImage(PioData));
    end procedure ResetAndLockMmcm;

    procedure DisplayConverterStatus is
    begin
      VPrint("Time: " & ImageUS(now));
      --DAC tile 0
      -- BusRd(16#4004#, PioData);
      -- VPrint("DAC Tile 0 - Restart Power-On State Machine Register: " & HexImage(PioData));
      -- BusRd(16#4008#, PioData);
      -- VPrint("DAC Tile 0 - Restart State Register: " & HexImage(PioData));
      -- BusRd(16#400C#, PioData);
      -- VPrint("DAC Tile 0 - Current State Register: " & HexImage(PioData));
      -- BusRd(16#4228#, PioData);
      -- VPrint("DAC Tile 0 - Common Status Register: " & HexImage(PioData));
      --ADC tile 0
      BusRd(16#11_4004#, PioData);
      VPrint("ADC Tile 0 - Restart Power-On State Machine Register: " & HexImage(PioData));
      BusRd(16#11_4008#, PioData);
      VPrint("ADC Tile 0 - Restart State Register: " & HexImage(PioData));
      BusRd(16#11_400C#, PioData);
      VPrint("ADC Tile 0 - Current State Register: " & HexImage(PioData));
      BusRd(16#11_4228#, PioData);
      VPrint("ADC Tile 0 - Common Status Register: " & HexImage(PioData));
    end procedure DisplayConverterStatus;
  begin
    rst <= true, false after 100 ns;

    wait for 1000 ns;
    ResetAndLockMmcm;


    wait for 100 us;
    BusRd(16#10_0000#, PioData);
    --IP Version Information
    VPrint("IP Version Information: " & HexImage(PioData));

    DisplayConverterStatus;
    wait for 50 us;
    DisplayConverterStatus;
    wait for 50 us;
    DisplayConverterStatus;
    wait for 50 us;
    DisplayConverterStatus;
    wait for 50 us;
    DisplayConverterStatus;
    wait for 50 us;
    DisplayConverterStatus;

    --now at 350 us

    --takes 350 (really 316.5) us for ADC to start up, 200 for DAC


    StopSim <= true;

    finish(2);
    wait;
  end process DriverProcess;

end test;
