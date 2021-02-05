--
-- Copyright 2020 Ettus Research, A National Instruments Company
--
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: tb_db_gpio
-- Description:
-- Testbench for DB GPIO connection

--nisim --op1="-L altera_mf_ver +nowarnTFMPC"

--synopsys translate_off
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work;
  use work.PkgNiSim.all;
  use work.PkgNiUtilities.all;
  use work.PkgCtrlPortTester.all;

entity tb_db_gpio is
  generic (
    kClockRatio : natural range 2 to 4 := 2 -- 3 is disallowed
  );
end tb_db_gpio;

architecture test of tb_db_gpio is

  component ctrlport_clk_cross
    port (
      rst                       : in  std_logic;
      s_ctrlport_clk            : in  std_logic;
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
      m_ctrlport_clk            : in  std_logic;
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
  component ctrlport_byte_deserializer
    port (
      ctrlport_clk             : in  std_logic;
      ctrlport_rst             : in  std_logic;
      m_ctrlport_req_wr        : out std_logic;
      m_ctrlport_req_rd        : out std_logic;
      m_ctrlport_req_addr      : out std_logic_vector(19 downto 0);
      m_ctrlport_req_data      : out std_logic_vector(31 downto 0);
      m_ctrlport_resp_ack      : in  std_logic;
      m_ctrlport_resp_status   : in  std_logic_vector(1 downto 0);
      m_ctrlport_resp_data     : in  std_logic_vector(31 downto 0);
      bytestream_data_in       : in  std_logic_vector(7 downto 0);
      bytestream_valid_in      : in  std_logic;
      bytestream_direction     : in  std_logic;
      bytestream_data_out      : out std_logic_vector(7 downto 0);
      bytestream_valid_out     : out std_logic;
      bytestream_output_enable : out std_logic);
  end component;
  component db_gpio_reordering
    port (
      db0_gpio_in_int     : out std_logic_vector(19 downto 0);
      db0_gpio_out_int    : in  std_logic_vector(19 downto 0);
      db0_gpio_out_en_int : in  std_logic_vector(19 downto 0);
      db1_gpio_in_int     : out std_logic_vector(19 downto 0);
      db1_gpio_out_int    : in  std_logic_vector(19 downto 0);
      db1_gpio_out_en_int : in  std_logic_vector(19 downto 0);
      db0_gpio_in_ext     : in  std_logic_vector(19 downto 0);
      db0_gpio_out_ext    : out std_logic_vector(19 downto 0);
      db0_gpio_out_en_ext : out std_logic_vector(19 downto 0);
      db1_gpio_in_ext     : in  std_logic_vector(19 downto 0);
      db1_gpio_out_ext    : out std_logic_vector(19 downto 0);
      db1_gpio_out_en_ext : out std_logic_vector(19 downto 0));
  end component;
  component db_gpio_interface
    port (
      radio_clk               : in  std_logic;
      pll_ref_clk             : in  std_logic;
      db_state                : in  std_logic_vector(3 downto 0);
      radio_time              : in  std_logic_vector(63 downto 0);
      radio_time_stb          : in  std_logic;
      time_ignore_bits        : in  std_logic_vector(3 downto 0);
      ctrlport_rst            : in  std_logic;
      s_ctrlport_req_wr       : in  std_logic;
      s_ctrlport_req_rd       : in  std_logic;
      s_ctrlport_req_addr     : in  std_logic_vector(19 downto 0);
      s_ctrlport_req_data     : in  std_logic_vector(31 downto 0);
      s_ctrlport_req_byte_en  : in  std_logic_vector(3 downto 0);
      s_ctrlport_req_has_time : in  std_logic;
      s_ctrlport_req_time     : in  std_logic_vector(63 downto 0);
      s_ctrlport_resp_ack     : out std_logic;
      s_ctrlport_resp_status  : out std_logic_vector(1 downto 0);
      s_ctrlport_resp_data    : out std_logic_vector(31 downto 0);
      gpio_in                 : in  std_logic_vector(19 downto 0);
      gpio_out                : out std_logic_vector(19 downto 0);
      gpio_out_en             : out std_logic_vector(19 downto 0);
      version_info            : out std_logic_vector(95 downto 0));
  end component;

  --vhook_sigstart
  signal cpld_ctrlport_req_addr: std_logic_vector(19 downto 0);
  signal cpld_ctrlport_req_data: std_logic_vector(31 downto 0);
  signal cpld_ctrlport_req_rd: std_logic;
  signal cpld_ctrlport_req_wr: std_logic;
  signal cpld_ctrlport_resp_ack: std_logic;
  signal cpld_ctrlport_resp_data: std_logic_vector(31 downto 0);
  signal cpld_ctrlport_resp_status: std_logic_vector(1 downto 0);
  signal gpio_data_out: std_logic_vector(7 downto 0);
  signal gpio_in_ext: std_logic_vector(19 downto 0);
  signal gpio_in_int: std_logic_vector(19 downto 0);
  signal gpio_out_en_ext: std_logic_vector(19 downto 0);
  signal gpio_out_en_int: std_logic_vector(19 downto 0);
  signal gpio_out_ext: std_logic_vector(19 downto 0);
  signal gpio_out_int: std_logic_vector(19 downto 0);
  signal gpio_output_enable: std_logic;
  signal gpio_valid_out: std_logic;
  signal origin_ctrlport_req_addr: std_logic_vector(19 downto 0);
  signal origin_ctrlport_req_data: std_logic_vector(31 downto 0);
  signal origin_ctrlport_req_rd: std_logic;
  signal origin_ctrlport_req_wr: std_logic;
  signal origin_ctrlport_resp_ack: std_logic;
  signal origin_ctrlport_resp_data: std_logic_vector(31 downto 0);
  signal origin_ctrlport_resp_status: std_logic_vector(1 downto 0);
  signal radio_time_stb: std_logic;
  signal target_ctrlport_req_addr: std_logic_vector(19 downto 0);
  signal target_ctrlport_req_data: std_logic_vector(31 downto 0);
  signal target_ctrlport_req_rd: std_logic;
  signal target_ctrlport_req_wr: std_logic;
  signal target_ctrlport_resp_ack: std_logic;
  signal target_ctrlport_resp_data: std_logic_vector(31 downto 0);
  signal target_ctrlport_resp_status: std_logic_vector(1 downto 0);
  --vhook_sigend

  -- clocking
  signal StopSim : boolean;
  constant kPrcPer : time := 16 ns;  -- 62,5 MHz
  constant kRadioPer : time := kPrcPer / kClockRatio;
  constant kCpldPer : time := 20 ns; -- 50 Mhz

  signal pll_ref_clk : std_logic := '1';
  signal radio_clk : std_logic := '1';
  signal cpld_clk : std_logic := '0';

  -- reset
  signal reset_prc : std_logic := '0';
  signal reset_rc : std_logic := '0';

  -- random variables for data transfer
  -- master to slave
  shared variable TxRandSource, TxRandCheck : Random_t;
  -- slave to master
  shared variable RxRandSource, RxRandCheck : Random_t;

  -- gpio wires
  type tIntArray is array (13 downto 0) of integer;
  -- Subset of GPIO port mappings from fpga/usrp3/top/x400/db_gpio_reordering.v
  -- Accounted for ZBX specific wire assignment of
  -- 5 unused, 10 used, 1 unused and 4 used signals out of the 20 FPGA GPIOs.
  -- The 6 unused indices are deleted from list.
  constant port0FpgaIndices : tIntArray := (10,4,5,16,18,8,6,1,9,2,11,7,13,12);
  signal gpio_mb : std_logic_vector(19 downto 0);
  signal gpio_db : std_logic_vector(13 downto 0);

  -- timestamps for ctrlport request
  signal radio_time: std_logic_vector(63 downto 0) := (others => '0');
  signal origin_ctrlport_req_has_time : std_logic := '0';
  signal origin_ctrlport_req_time : std_logic_vector(63 downto 0) := (others => '0');

begin

  assert kClockRatio /= 3
    report "Clock ratio 3 is not allowed"
    severity failure;

  ------------------------------------------------------------------------------
  -- clock generation
  ------------------------------------------------------------------------------
  pll_ref_clk <= not pll_ref_clk after kPrcPer/2 when not StopSim else '0';
  radio_clk <= not radio_clk after kRadioPer/2 when not StopSim else '0';
  cpld_clk <= not cpld_clk after kCpldPer/2 when not StopSim else '0';

  ------------------------------------------------------------------------------
  -- DUTs
  ------------------------------------------------------------------------------
  --vhook_e CtrlPortMasterModel
  --vhook_a kThreadId         0
  --vhook_a kHoldAccess       true
  --vhook_a kClkCycleTimeout  1000
  --vhook_a ctrlport_clk      radio_clk
  --vhook_a ctrlport_rst      to_Boolean(reset_rc)
  --vhook_a {m_ctrlport_(.*)} origin_ctrlport_$1
  CtrlPortMasterModelx: entity work.CtrlPortMasterModel (behav)
    generic map (
      kThreadId        => 0,     --natural:=0
      kHoldAccess      => true,  --boolean:=true
      kClkCycleTimeout => 1000)  --natural:=1000
    port map (
      ctrlport_rst           => to_Boolean(reset_rc),         --in  boolean
      ctrlport_clk           => radio_clk,                    --in  std_logic
      m_ctrlport_req_wr      => origin_ctrlport_req_wr,       --out std_logic
      m_ctrlport_req_rd      => origin_ctrlport_req_rd,       --out std_logic
      m_ctrlport_req_addr    => origin_ctrlport_req_addr,     --out std_logic_vector(19:0)
      m_ctrlport_req_data    => origin_ctrlport_req_data,     --out std_logic_vector(31:0)
      m_ctrlport_resp_ack    => origin_ctrlport_resp_ack,     --in  std_logic
      m_ctrlport_resp_status => origin_ctrlport_resp_status,  --in  std_logic_vector(1 :0)
      m_ctrlport_resp_data   => origin_ctrlport_resp_data);   --in  std_logic_vector(31:0)

  --vhook db_gpio_interface
  --vhook_a db_state (others => '0')
  --vhook_a time_ignore_bits x"0"
  --vhook_a s_ctrlport_req_byte_en (others => '0')
  --vhook_a {s_ctrlport_(.*)} origin_ctrlport_$1
  --vhook_a {^gpio(.*)} gpio$1_int
  --vhook_a ctrlport_rst reset_rc
  --vhook_a version_info open
  db_gpio_interfacex: db_gpio_interface
    port map (
      radio_clk               => radio_clk,                     --in  wire
      pll_ref_clk             => pll_ref_clk,                   --in  wire
      db_state                => (others => '0'),               --in  wire[3:0]
      radio_time              => radio_time,                    --in  wire[63:0]
      radio_time_stb          => radio_time_stb,                --in  wire
      time_ignore_bits        => x"0",                          --in  wire[3:0]
      ctrlport_rst            => reset_rc,                      --in  wire
      s_ctrlport_req_wr       => origin_ctrlport_req_wr,        --in  wire
      s_ctrlport_req_rd       => origin_ctrlport_req_rd,        --in  wire
      s_ctrlport_req_addr     => origin_ctrlport_req_addr,      --in  wire[19:0]
      s_ctrlport_req_data     => origin_ctrlport_req_data,      --in  wire[31:0]
      s_ctrlport_req_byte_en  => (others => '0'),               --in  wire[3:0]
      s_ctrlport_req_has_time => origin_ctrlport_req_has_time,  --in  wire
      s_ctrlport_req_time     => origin_ctrlport_req_time,      --in  wire[63:0]
      s_ctrlport_resp_ack     => origin_ctrlport_resp_ack,      --out wire
      s_ctrlport_resp_status  => origin_ctrlport_resp_status,   --out wire[1:0]
      s_ctrlport_resp_data    => origin_ctrlport_resp_data,     --out wire[31:0]
      gpio_in                 => gpio_in_int,                   --in  wire[19:0]
      gpio_out                => gpio_out_int,                  --out wire[19:0]
      gpio_out_en             => gpio_out_en_int,               --out wire[19:0]
      version_info            => open);                         --out wire[95:0]

  --vhook db_gpio_reordering
  --vhook_a {db1_(.*)} {open} mode=out
  --vhook_a {db1_(.*)} (others => '0') mode=in
  --vhook_a {db0_(.*)} {$1}
  db_gpio_reorderingx: db_gpio_reordering
    port map (
      db0_gpio_in_int     => gpio_in_int,      --out wire[19:0]
      db0_gpio_out_int    => gpio_out_int,     --in  wire[19:0]
      db0_gpio_out_en_int => gpio_out_en_int,  --in  wire[19:0]
      db1_gpio_in_int     => open,             --out wire[19:0]
      db1_gpio_out_int    => (others => '0'),  --in  wire[19:0]
      db1_gpio_out_en_int => (others => '0'),  --in  wire[19:0]
      db0_gpio_in_ext     => gpio_in_ext,      --in  wire[19:0]
      db0_gpio_out_ext    => gpio_out_ext,     --out wire[19:0]
      db0_gpio_out_en_ext => gpio_out_en_ext,  --out wire[19:0]
      db1_gpio_in_ext     => (others => '0'),  --in  wire[19:0]
      db1_gpio_out_ext    => open,             --out wire[19:0]
      db1_gpio_out_en_ext => open);            --out wire[19:0]

  ------------------------------------------------------------------------------
  -- FPGA Mapping to GPIO signal
  ------------------------------------------------------------------------------
  --gpio_in_ext <= gpio_mb;
  fpga_gen: for i in gpio_mb'range generate
    gpio_mb(i) <= gpio_out_ext(i) when gpio_out_en_ext(i) else 'Z';
  end generate;

  ------------------------------------------------------------------------------
  -- Motherboard trace connections
  ------------------------------------------------------------------------------
  -- map according to DB 0 mapping on Rev B X400 motherboard
  -- see definition of port0FpgaIndices for details
  mapping_gen: for i in port0FpgaIndices'range generate
    gpio_db(i) <= gpio_mb(port0FpgaIndices(i));
    gpio_in_ext(port0FpgaIndices(i)) <= gpio_db(i);
  end generate;

  -------------------------------------------------------------------------------
  -- CPLD Mapping to GPIO signal
  -------------------------------------------------------------------------------
  gpio_db(12) <= gpio_valid_out when gpio_output_enable else 'Z';
  cpld_gen: for i in gpio_data_out'range generate
    gpio_db(i+4) <= gpio_data_out(i) when gpio_output_enable else 'Z';
  end generate;

  --vhook ctrlport_byte_deserializer
  --vhook_a ctrlport_clk pll_ref_clk
  --vhook_a ctrlport_rst reset_prc
  --vhook_a {m_ctrlport_(.*)} cpld_ctrlport_$1
  --vhook_a bytestream_direction gpio_db(13)
  --vhook_a bytestream_valid_in gpio_db(12)
  --vhook_a bytestream_data_in gpio_db(11 downto 4)
  --vhook_a {^bytestream(.*)} gpio$1
  ctrlport_byte_deserializerx: ctrlport_byte_deserializer
    port map (
      ctrlport_clk             => pll_ref_clk,                --in  wire
      ctrlport_rst             => reset_prc,                  --in  wire
      m_ctrlport_req_wr        => cpld_ctrlport_req_wr,       --out wire
      m_ctrlport_req_rd        => cpld_ctrlport_req_rd,       --out wire
      m_ctrlport_req_addr      => cpld_ctrlport_req_addr,     --out wire[19:0]
      m_ctrlport_req_data      => cpld_ctrlport_req_data,     --out wire[31:0]
      m_ctrlport_resp_ack      => cpld_ctrlport_resp_ack,     --in  wire
      m_ctrlport_resp_status   => cpld_ctrlport_resp_status,  --in  wire[1:0]
      m_ctrlport_resp_data     => cpld_ctrlport_resp_data,    --in  wire[31:0]
      bytestream_data_in       => gpio_db(11 downto 4),       --in  wire[7:0]
      bytestream_valid_in      => gpio_db(12),                --in  wire
      bytestream_direction     => gpio_db(13),                --in  wire
      bytestream_data_out      => gpio_data_out,              --out wire[7:0]
      bytestream_valid_out     => gpio_valid_out,             --out wire
      bytestream_output_enable => gpio_output_enable);        --out wire

  --vhook ctrlport_clk_cross
  --vhook_a rst reset_prc
  --vhook_a s_ctrlport_clk pll_ref_clk
  --vhook_a m_ctrlport_clk cpld_clk
  --vhook_a {s_ctrlport_(.*)id} (others => '0')
  --vhook_a s_ctrlport_req_has_time '0'
  --vhook_a s_ctrlport_req_time (others => '0')
  --vhook_a s_ctrlport_req_byte_en (others => '0')
  --vhook_a {s_ctrlport_(.*)} cpld_ctrlport_$1
  --vhook_a {m_ctrlport_(.*)id} open
  --vhook_a {m_ctrlport_(.*)time} open
  --vhook_a {m_ctrlport_(.*)byte_en} open
  --vhook_a {m_ctrlport_(.*)} target_ctrlport_$1
  ctrlport_clk_crossx: ctrlport_clk_cross
    port map (
      rst                       => reset_prc,                    --in  wire
      s_ctrlport_clk            => pll_ref_clk,                  --in  wire
      s_ctrlport_req_wr         => cpld_ctrlport_req_wr,         --in  wire
      s_ctrlport_req_rd         => cpld_ctrlport_req_rd,         --in  wire
      s_ctrlport_req_addr       => cpld_ctrlport_req_addr,       --in  wire[19:0]
      s_ctrlport_req_portid     => (others => '0'),              --in  wire[9:0]
      s_ctrlport_req_rem_epid   => (others => '0'),              --in  wire[15:0]
      s_ctrlport_req_rem_portid => (others => '0'),              --in  wire[9:0]
      s_ctrlport_req_data       => cpld_ctrlport_req_data,       --in  wire[31:0]
      s_ctrlport_req_byte_en    => (others => '0'),              --in  wire[3:0]
      s_ctrlport_req_has_time   => '0',                          --in  wire
      s_ctrlport_req_time       => (others => '0'),              --in  wire[63:0]
      s_ctrlport_resp_ack       => cpld_ctrlport_resp_ack,       --out wire
      s_ctrlport_resp_status    => cpld_ctrlport_resp_status,    --out wire[1:0]
      s_ctrlport_resp_data      => cpld_ctrlport_resp_data,      --out wire[31:0]
      m_ctrlport_clk            => cpld_clk,                     --in  wire
      m_ctrlport_req_wr         => target_ctrlport_req_wr,       --out wire
      m_ctrlport_req_rd         => target_ctrlport_req_rd,       --out wire
      m_ctrlport_req_addr       => target_ctrlport_req_addr,     --out wire[19:0]
      m_ctrlport_req_portid     => open,                         --out wire[9:0]
      m_ctrlport_req_rem_epid   => open,                         --out wire[15:0]
      m_ctrlport_req_rem_portid => open,                         --out wire[9:0]
      m_ctrlport_req_data       => target_ctrlport_req_data,     --out wire[31:0]
      m_ctrlport_req_byte_en    => open,                         --out wire[3:0]
      m_ctrlport_req_has_time   => open,                         --out wire
      m_ctrlport_req_time       => open,                         --out wire[63:0]
      m_ctrlport_resp_ack       => target_ctrlport_resp_ack,     --in  wire
      m_ctrlport_resp_status    => target_ctrlport_resp_status,  --in  wire[1:0]
      m_ctrlport_resp_data      => target_ctrlport_resp_data);   --in  wire[31:0]


timekeeper: process
begin
  radio_time_stb <= '0';
  wait until falling_edge(pll_ref_clk);
  radio_time_stb <= '1';
  radio_time <= std_logic_vector(unsigned(radio_time) + 1);
  wait until falling_edge(pll_ref_clk);
end process;

main: process
  variable readData    : std_logic_vector(31 downto 0) := (others=>'0');
  variable readStatus  : std_logic_vector(1  downto 0) := (others=>'0');
  variable ctrlportAck : std_logic;
begin
  -- initial reset
  reset_prc <= '1';
  reset_rc <= '1';
  wait for 43 ns;

  wait until rising_edge(pll_ref_clk);
  reset_prc <= '0';
  wait until rising_edge(radio_clk);
  reset_rc <= '0';

  -- wait for at least 10 clock cycles to release handshakes from reset
  wait for kPrcPer*10;

  -- issue write and read requests
  for i in 0 to 1000 loop
    wait until rising_edge(radio_clk);
    if TxRandSource.GetBoolean(0.5) then
      origin_ctrlport_req_has_time <= '1';
      origin_ctrlport_req_time <= std_logic_vector(unsigned(radio_time) + 14);
      CtrlPortWrite(to_integer(TxRandSource.GetUnsigned(15)), TxRandSource.GetStdLogicVector(32));
    else
      origin_ctrlport_req_has_time <= '0';
      CtrlPortRead(to_integer(TxRandSource.GetUnsigned(15)), readData, readStatus, ctrlportAck);
      assert readData = RxRandCheck.GetStdLogicVector(32) report "incorrect data from slave" severity error;
      assert readStatus = "00" report "incorrect status from slave" severity error;
      assert ctrlportAck = '1' report "ack missing" severity error;
    end if;
  end loop;

  StopSim <= true;
end process;

-- check received requests
ctrlport_check: process
begin
  -- default assignments for response wires
  target_ctrlport_resp_ack <= '0';
  target_ctrlport_resp_status <= "00";
  target_ctrlport_resp_data <= (others => 'X');

  wait until target_ctrlport_req_rd = '1' or target_ctrlport_req_wr = '1' for 10 us;
  wait until falling_edge(cpld_clk);
  if TxRandCheck.GetBoolean(0.5) then
    assert target_ctrlport_req_rd = '0' report "Read received but write expected." severity error;
    assert target_ctrlport_req_wr = '1' report "There has to be a write request." severity error;
    assert target_ctrlport_req_addr = "00000" & std_logic_vector(TxRandCheck.GetUnsigned(15)) report "incorrect address" severity error;
    assert target_ctrlport_req_data = TxRandCheck.GetStdLogicVector(32) report "incorrect data" severity error;
  else
    assert target_ctrlport_req_rd = '1' report "There has to be a read request." severity error;
    assert target_ctrlport_req_wr = '0' report "Write received but read expected." severity error;
    assert target_ctrlport_req_addr = "00000" & std_logic_vector(TxRandCheck.GetUnsigned(15)) report "incorrect address" severity error;
    target_ctrlport_resp_data <= RxRandSource.GetStdLogicVector(32);
    --target_ctrlport_resp_status <= RxRandSource.GetStdLogicVector(2);
  end if;

  -- ack for 1 clock cycle
  wait until falling_edge(cpld_clk);
  target_ctrlport_resp_ack <= '1';
  wait until falling_edge(cpld_clk);
end process;

-- check ctrlport gpio protocol
protocolCheck: process
  -- output enable lines
  variable cpldOutputEnable : std_logic := '0';
  variable fpgaOutputEnable : std_logic := '0';
  -- intermediate signals
  variable pauseCycle : boolean := false;
  variable lastPauseCycle : boolean := false;
  -- save last FPGA output enable state
  variable lastFpgaOutputEnable : std_logic := '0';
  variable lastCpldOutputEnable : std_logic := '0';
  -- initial start of checks after reset
  variable pauseChecksEnabled : boolean := false;
begin
  wait until falling_edge(pll_ref_clk);
  -- get data to variables
  cpldOutputEnable := gpio_output_enable;
  -- gpio_out_en_int changes on the falling edge of pll_ref_clk,
  -- we need a simulation delta cycle for it to be reflected.
  wait for 1 ps;
  fpgaOutputEnable := gpio_out_en_int(5);
  pauseCycle := (cpldOutputEnable or fpgaOutputEnable) /= '1';
  lastPauseCycle := (lastCpldOutputEnable or lastFpgaOutputEnable) /= '1';

  -- check output enables not being active at the same time
  assert (cpldOutputEnable and fpgaOutputEnable) = '0'
    report "The output enables are not allowed to be active at the same time." severity error;

  -- check double assignment
  for i in gpio_db'range loop
    assert gpio_db(i) /= 'X' report "double assignment to GPIO connection" severity error;
  end loop;

  -- check change in output enable -> valid not allowed immediately after change
  if (lastFpgaOutputEnable /= fpgaOutputEnable) then
    assert gpio_db(12) /= '1' report "no data transmission in clock cycle after output enable change of FPGA allowed" severity error;
  end if;

  -- check pause cycles
  if (pauseChecksEnabled) then
    if (not lastFpgaOutputEnable and fpgaOutputEnable) then
      assert lastPauseCycle report "There has to be a pause cycle before enabling the FPGA output enable" severity error;
    end if;
    if (not lastCpldOutputEnable and cpldOutputEnable) then
      assert lastPauseCycle report "There has to be a pause cycle before enabling the CPLD output enable" severity error;
    end if;
    if pauseCycle then
      assert (lastCpldOutputEnable or lastFpgaOutputEnable) = '1' report "Only one clock cycle on bus allowed" severity error;
    end if;
  else
    pauseChecksEnabled := (fpgaOutputEnable = '1') and (reset_prc = '0');
  end if;

  -- save for next cycle
  lastFpgaOutputEnable := fpgaOutputEnable;
  lastCpldOutputEnable := cpldOutputEnable;

end process;
end test;
