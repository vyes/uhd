--
-- Copyright 2019 Ettus Research, A National Instruments Company
--
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: tb_cpld_interface
-- Description:
-- Testbench for cpld_interface

--nisim --op1="-L fifo_generator_v13_2_4"

--synopsys translate_off
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work;
  use work.PkgNiSim.all;
  use work.PkgNiUtilities.all;
  use work.PkgPL_CPLD_REGMAP.all;
  use work.PkgCPLD_INTERFACE_REGMAP.all;
  use work.PkgMB_CPLD_PL_REGMAP.kPL_REGISTERS;
  use work.PkgPL_CPLD_BASE_REGMAP.kLED_REGISTER;
  use work.PkgPL_CPLD_BASE_REGMAP.kCABLE_PRESENT_REG;
  use work.PkgPL_CPLD_BASE_REGMAP.kIPASS0_CABLE_PRESENT;
  use work.PkgVERSIONING_REGS_REGMAP.all;

entity tb_cpld_interface is end tb_cpld_interface;

architecture test of tb_cpld_interface is

  component spi_slave_to_ctrlport_master
    generic (
      CLK_FREQUENCY : integer := 50000000;
      SPI_FREQUENCY : integer := 10000000);
    port (
      ctrlport_clk           : in  std_logic;
      ctrlport_rst           : in  std_logic;
      m_ctrlport_req_wr      : out std_logic;
      m_ctrlport_req_rd      : out std_logic;
      m_ctrlport_req_addr    : out std_logic_vector(19 downto 0);
      m_ctrlport_req_data    : out std_logic_vector(31 downto 0);
      m_ctrlport_resp_ack    : in  std_logic;
      m_ctrlport_resp_status : in  std_logic_vector(1 downto 0);
      m_ctrlport_resp_data   : in  std_logic_vector(31 downto 0);
      sclk                   : in  std_logic;
      cs_n                   : in  std_logic;
      mosi                   : in  std_logic;
      miso                   : out std_logic);
  end component;
  component cpld_interface
    port (
      s_axi_aclk              : in  std_logic;
      s_axi_aresetn           : in  std_logic;
      pll_ref_clk             : in  std_logic;
      radio_clk               : in  std_logic;
      ctrlport_rst            : in  std_logic;
      radio_time              : in  std_logic_vector(63 downto 0);
      radio_time_stb          : in  std_logic;
      time_ignore_bits        : in  std_logic_vector(3 downto 0);
      s_axi_awaddr            : in  std_logic_vector(16 downto 0);
      s_axi_awvalid           : in  std_logic;
      s_axi_awready           : out std_logic;
      s_axi_wdata             : in  std_logic_vector(31 downto 0);
      s_axi_wstrb             : in  std_logic_vector(3 downto 0);
      s_axi_wvalid            : in  std_logic;
      s_axi_wready            : out std_logic;
      s_axi_bresp             : out std_logic_vector(1 downto 0);
      s_axi_bvalid            : out std_logic;
      s_axi_bready            : in  std_logic;
      s_axi_araddr            : in  std_logic_vector(16 downto 0);
      s_axi_arvalid           : in  std_logic;
      s_axi_arready           : out std_logic;
      s_axi_rdata             : out std_logic_vector(31 downto 0);
      s_axi_rresp             : out std_logic_vector(1 downto 0);
      s_axi_rvalid            : out std_logic;
      s_axi_rready            : in  std_logic;
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
      ss                      : out std_logic_vector(1 downto 0);
      sclk                    : out std_logic;
      mosi                    : out std_logic;
      miso                    : in  std_logic;
      qsfp0_led_active        : in  std_logic_vector(3 downto 0);
      qsfp0_led_link          : in  std_logic_vector(3 downto 0);
      qsfp1_led_active        : in  std_logic_vector(3 downto 0);
      qsfp1_led_link          : in  std_logic_vector(3 downto 0);
      ipass_present_n         : in  std_logic_vector(1 downto 0);
      version_info            : out std_logic_vector(95 downto 0));
  end component;

  --vhook_sigstart
  signal app_ctrlport_req_addr: std_logic_vector(19 downto 0);
  signal app_ctrlport_req_byte_en: std_logic_vector(3 downto 0);
  signal app_ctrlport_req_data: std_logic_vector(31 downto 0);
  signal app_ctrlport_req_has_time: std_logic;
  signal app_ctrlport_req_rd: std_logic;
  signal app_ctrlport_req_time: std_logic_vector(63 downto 0);
  signal app_ctrlport_req_wr: std_logic;
  signal app_ctrlport_resp_ack: std_logic;
  signal app_ctrlport_resp_data: std_logic_vector(31 downto 0);
  signal app_ctrlport_resp_status: std_logic_vector(1 downto 0);
  signal cs_n: std_logic;
  signal ctrlport_rst: std_logic;
  signal ipass_present_n: std_logic_vector(1 downto 0);
  signal m_ctrlport_req_addr: std_logic_vector(19 downto 0);
  signal m_ctrlport_req_data: std_logic_vector(31 downto 0);
  signal m_ctrlport_req_rd: std_logic;
  signal m_ctrlport_req_wr: std_logic;
  signal m_ctrlport_resp_ack: std_logic;
  signal m_ctrlport_resp_data: std_logic_vector(31 downto 0);
  signal m_ctrlport_resp_status: std_logic_vector(1 downto 0);
  signal miso: std_logic;
  signal mosi: std_logic;
  signal pll_ref_clk: std_logic := '0';
  signal qsfp0_led_active: std_logic_vector(3 downto 0);
  signal qsfp0_led_link: std_logic_vector(3 downto 0);
  signal qsfp1_led_active: std_logic_vector(3 downto 0);
  signal qsfp1_led_link: std_logic_vector(3 downto 0);
  signal radio_clk: std_logic := '0';
  signal s_axi_aclk: std_logic := '0';
  signal s_axi_araddr: std_logic_vector(16 downto 0);
  signal s_axi_aresetn: std_logic;
  signal s_axi_arready: std_logic;
  signal s_axi_arvalid: std_logic;
  signal s_axi_awaddr: std_logic_vector(16 downto 0);
  signal s_axi_awready: std_logic;
  signal s_axi_awvalid: std_logic;
  signal s_axi_bready: std_logic;
  signal s_axi_bresp: std_logic_vector(1 downto 0);
  signal s_axi_bvalid: std_logic;
  signal s_axi_rdata: std_logic_vector(31 downto 0);
  signal s_axi_rready: std_logic;
  signal s_axi_rresp: std_logic_vector(1 downto 0);
  signal s_axi_rvalid: std_logic;
  signal s_axi_wdata: std_logic_vector(31 downto 0);
  signal s_axi_wready: std_logic;
  signal s_axi_wstrb: std_logic_vector(3 downto 0);
  signal s_axi_wvalid: std_logic;
  signal sclk: std_logic := '0';
  signal ss: std_logic_vector(1 downto 0);
  signal version_info: std_logic_vector(95 downto 0);
  --vhook_sigend

  -- BuildVersion and BuildComponentVersions models the behavior of versioning_utils.vh
  function BuildVersion (
    major, minor, build : integer)
  return std_logic_vector is
    variable version : std_logic_vector(kVERSION_TYPESize-1 downto 0);
  begin
    version(kMAJORMsb downto kMAJOR) := std_logic_vector(to_unsigned(major, kMAJORSize));
    version(kMINORMsb downto kMINOR) := std_logic_vector(to_unsigned(minor, kMINORSize));
    version(kBUILDMsb downto kBUILD) := std_logic_vector(to_unsigned(build, kBUILDSize));
    return version;
  end function BuildVersion;

  function BuildComponentVersions (
    timestamp, oldestCompatibleVersion, currentVersion : std_logic_vector)
  return std_logic_vector is
    variable version : std_logic_vector(95 downto 0);
  begin
    version(31 downto  0) := currentVersion;
    version(63 downto 32) := oldestCompatibleVersion;
    version(95 downto 64) := timestamp;
    return version;
  end function BuildComponentVersions;

  signal StopSim : boolean;
  shared variable Rand : Random_t;
  constant kAxiPer : time := 25 ns;  -- 40 MHz
  constant kPrcPer : time := 16 ns;  -- 62,5 MHz
  constant kRadioPer : time := 8 ns;  -- 125 MHz

  signal radio_time: std_logic_vector(63 downto 0) := (others => '0');
  signal radio_time_stb: std_logic := '0';

begin

  s_axi_aclk <= not s_axi_aclk after kAxiPer/2 when not StopSim else '0';
  pll_ref_clk <= not pll_ref_clk after kPrcPer/2 when not StopSim else '0';
  radio_clk <= not radio_clk after kRadioPer/2 when not StopSim else '0';

  --vhook cpld_interface dutx
  --vhook_a time_ignore_bits x"0"
  --vhook_a {s_ctrlport_(.*)} app_ctrlport_$1
  dutx: cpld_interface
    port map (
      s_axi_aclk              => s_axi_aclk,                 --in  wire
      s_axi_aresetn           => s_axi_aresetn,              --in  wire
      pll_ref_clk             => pll_ref_clk,                --in  wire
      radio_clk               => radio_clk,                  --in  wire
      ctrlport_rst            => ctrlport_rst,               --in  wire
      radio_time              => radio_time,                 --in  wire[63:0]
      radio_time_stb          => radio_time_stb,             --in  wire
      time_ignore_bits        => x"0",                       --in  wire[3:0]
      s_axi_awaddr            => s_axi_awaddr,               --in  wire[16:0]
      s_axi_awvalid           => s_axi_awvalid,              --in  wire
      s_axi_awready           => s_axi_awready,              --out wire
      s_axi_wdata             => s_axi_wdata,                --in  wire[31:0]
      s_axi_wstrb             => s_axi_wstrb,                --in  wire[3:0]
      s_axi_wvalid            => s_axi_wvalid,               --in  wire
      s_axi_wready            => s_axi_wready,               --out wire
      s_axi_bresp             => s_axi_bresp,                --out wire[1:0]
      s_axi_bvalid            => s_axi_bvalid,               --out wire
      s_axi_bready            => s_axi_bready,               --in  wire
      s_axi_araddr            => s_axi_araddr,               --in  wire[16:0]
      s_axi_arvalid           => s_axi_arvalid,              --in  wire
      s_axi_arready           => s_axi_arready,              --out wire
      s_axi_rdata             => s_axi_rdata,                --out wire[31:0]
      s_axi_rresp             => s_axi_rresp,                --out wire[1:0]
      s_axi_rvalid            => s_axi_rvalid,               --out wire
      s_axi_rready            => s_axi_rready,               --in  wire
      s_ctrlport_req_wr       => app_ctrlport_req_wr,        --in  wire
      s_ctrlport_req_rd       => app_ctrlport_req_rd,        --in  wire
      s_ctrlport_req_addr     => app_ctrlport_req_addr,      --in  wire[19:0]
      s_ctrlport_req_data     => app_ctrlport_req_data,      --in  wire[31:0]
      s_ctrlport_req_byte_en  => app_ctrlport_req_byte_en,   --in  wire[3:0]
      s_ctrlport_req_has_time => app_ctrlport_req_has_time,  --in  wire
      s_ctrlport_req_time     => app_ctrlport_req_time,      --in  wire[63:0]
      s_ctrlport_resp_ack     => app_ctrlport_resp_ack,      --out wire
      s_ctrlport_resp_status  => app_ctrlport_resp_status,   --out wire[1:0]
      s_ctrlport_resp_data    => app_ctrlport_resp_data,     --out wire[31:0]
      ss                      => ss,                         --out wire[1:0]
      sclk                    => sclk,                       --out wire
      mosi                    => mosi,                       --out wire
      miso                    => miso,                       --in  wire
      qsfp0_led_active        => qsfp0_led_active,           --in  wire[3:0]
      qsfp0_led_link          => qsfp0_led_link,             --in  wire[3:0]
      qsfp1_led_active        => qsfp1_led_active,           --in  wire[3:0]
      qsfp1_led_link          => qsfp1_led_link,             --in  wire[3:0]
      ipass_present_n         => ipass_present_n,            --in  wire[1:0]
      version_info            => version_info);              --out wire[95:0]

  -- one receiver regardless of selected slave for simulation simplicity
  cs_n <= ss(0) and ss(1);

  --vhook spi_slave_to_ctrlport_master receiver
  --vhook_a CLK_FREQUENCY 62500000
  --vhook_a SPI_FREQUENCY 31250000
  --vhook_a ctrlport_clk pll_ref_clk
  receiver: spi_slave_to_ctrlport_master
    generic map (
      CLK_FREQUENCY => 62500000,  --integer:=50000000
      SPI_FREQUENCY => 31250000)  --integer:=10000000
    port map (
      ctrlport_clk           => pll_ref_clk,             --in  wire
      ctrlport_rst           => ctrlport_rst,            --in  wire
      m_ctrlport_req_wr      => m_ctrlport_req_wr,       --out wire
      m_ctrlport_req_rd      => m_ctrlport_req_rd,       --out wire
      m_ctrlport_req_addr    => m_ctrlport_req_addr,     --out wire[19:0]
      m_ctrlport_req_data    => m_ctrlport_req_data,     --out wire[31:0]
      m_ctrlport_resp_ack    => m_ctrlport_resp_ack,     --in  wire
      m_ctrlport_resp_status => m_ctrlport_resp_status,  --in  wire[1:0]
      m_ctrlport_resp_data   => m_ctrlport_resp_data,    --in  wire[31:0]
      sclk                   => sclk,                    --in  wire
      cs_n                   => cs_n,                    --in  wire
      mosi                   => mosi,                    --in  wire
      miso                   => miso);                   --out wire

  -- increment of time each 4 clock cycles
  timekeeper: process(radio_clk)
    variable counter : unsigned(1 downto 0) := (others => '0');
  begin
    if rising_edge(radio_clk) then
      counter := counter + 1;
      if (counter = 0) then
        radio_time <= std_logic_vector(unsigned(radio_time) + 1);
        radio_time_stb <= '1';
      else
        radio_time_stb <= '0';
      end if;
    end if;
  end process;

  main: process
    variable randomRequest: std_logic_vector(32+15+1-1 downto 0) := (others => '0');
    variable randomResponse: std_logic_vector(32+1-1 downto 0) := (others => '0');

    -- procedure for issue AXI lite write request
    procedure axiLiteWriteRequest(address : in std_logic_vector(16 downto 0); data : in std_logic_vector(31 downto 0)) is
    begin
      ClkWaitF(1, s_axi_aclk);
      s_axi_awaddr <= address;
      s_axi_awvalid <= '1';
      s_axi_wdata <= data;
      s_axi_wvalid <= '1';
      s_axi_wstrb <= (others => '1');

      -- wait for transfer and clear valid flags
      wait until s_axi_awready = '1' for 10 us;
      -- implicit knowledge about submodule, which takes data and address at the same time
      assert s_axi_awready = '1' report "axi write request failed (awready)" severity error;
      assert s_axi_wready = '1' report "axi write request failed (wready)" severity error;
      ClkWaitR(1, s_axi_aclk);
      ClkWaitF(1, s_axi_aclk);
      s_axi_awaddr <= (others => 'X');
      s_axi_awvalid <= '0';
      s_axi_wdata <= (others => 'X');
      s_axi_wvalid <= '0';
      s_axi_wstrb <= (others => 'X');
    end procedure axiLiteWriteRequest;

    -- procedure for issue AXI lite read request
    procedure axiLiteReadRequest(address : in std_logic_vector(16 downto 0)) is
    begin
      ClkWaitF(1, s_axi_aclk);
      s_axi_araddr <= address;
      s_axi_arvalid <= '1';

      -- wait for transfer and clear valid flags
      wait until s_axi_arready = '1' for 10 us;
      assert s_axi_arready = '1' report "axi read request failed" severity error;
      ClkWaitR(1, s_axi_aclk);
      ClkWaitF(1, s_axi_aclk);
      s_axi_araddr <= (others => 'X');
      s_axi_arvalid <= '0';
    end procedure axiLiteReadRequest;

    -- procedure for checking the controlport requests
    procedure checkControlportRequest(isWrite : in boolean; address : in std_logic_vector(14 downto 0); data : in std_logic_vector(31 downto 0)) is
    begin
      wait until rising_edge(m_ctrlport_req_wr) or rising_edge(m_ctrlport_req_rd) for 100 us;
      ClkWaitF(1, pll_ref_clk);
      assert m_ctrlport_req_wr = to_StdLogic(isWrite) report "controlport request type invalid" severity error;
      assert m_ctrlport_req_rd = to_StdLogic(not isWrite) report "controlport request type invalid" severity error;
      if (isWrite) then
        assert m_ctrlport_req_data = data report "controlport data invalid" severity error;
      end if;
      assert m_ctrlport_req_addr(address'range) = address report "controlport address invalid" severity error;
    end procedure checkControlportRequest;

    -- issue controlport response
    procedure issueControlportResponse(isError : in boolean; data : in std_logic_vector(31 downto 0)) is
    begin
      ClkWaitF(1, pll_ref_clk);
      m_ctrlport_resp_ack <= '1';
      m_ctrlport_resp_data <= data;
      -- error in case high flag is 1
      if (isError) then
        m_ctrlport_resp_status <= "01";
      else
        m_ctrlport_resp_status <= "00";
      end if;

      -- clear response
      ClkWaitF(1, pll_ref_clk);
      m_ctrlport_resp_ack <= '0';
      m_ctrlport_resp_data <= (others => 'X');
      m_ctrlport_resp_status <= (others => 'X');
    end procedure issueControlportResponse;

    procedure checkAxiWriteResponse (isError : in boolean) is
    begin
      -- wait for response
      ClkWaitF(1,s_axi_aclk);
      s_axi_bready <= '1';
      wait until s_axi_bvalid = '1' for 100 us;
      assert s_axi_bvalid = '1' report "axi write response missing" severity error;
      ClkWaitF(1, s_axi_aclk);
      if (isError) then
        assert s_axi_bresp = "10" report "axi response is not showing error" severity error;
      else
        assert s_axi_bresp = "00" report "axi response is not OKAY" severity error;
      end if;
      ClkWaitF(1, s_axi_aclk);
      s_axi_bready <= '0';
    end procedure checkAxiWriteResponse;

    procedure checkAxiReadResponse (isError : in boolean; expectedData : in std_logic_vector(31 downto 0)) is
    begin
      -- wait for response
      ClkWaitF(1,s_axi_aclk);
      s_axi_rready <= '1';
      wait until s_axi_rvalid = '1' for 100 us;
      assert s_axi_rvalid = '1' report "axi read response missing" severity error;
      ClkWaitF(1, s_axi_aclk);
      if (isError) then
        assert s_axi_rresp = "10" report "axi response is not showing error" severity error;
      else
        assert s_axi_rresp = "00" report "axi response is not OKAY" severity error;
        assert s_axi_rdata = expectedData report "axi read response data is incorrect" severity error;
      end if;
      ClkWaitF(1, s_axi_aclk);
      s_axi_rready <= '0';
    end procedure checkAxiReadResponse;

  begin
    -- default assignments
    app_ctrlport_req_wr <= '0';
    app_ctrlport_req_rd <= '0';
    app_ctrlport_req_data <= (others => 'X'); -- just use once to make vsmake happy
    ipass_present_n <= (others => '1'); -- start with unattached cables

    -- reset sequence
    s_axi_aresetn <= '0';
    ClkWaitF(1, pll_ref_clk);
    ctrlport_rst <= '1';
    ClkWaitF(1, pll_ref_clk);
    ctrlport_rst <= '0';
    wait for 100 ns;
    s_axi_aresetn <= '1';

    -- eRFNoc spec defines a wait time of 100us for modules to reset
    wait for 100 us;

    -- check version info
    assert version_info = BuildComponentVersions(
      std_logic_vector(to_unsigned(kCPLD_IFC_VERSION_LAST_MODIFIED_TIME, 32)),
      BuildVersion(
        kCPLD_IFC_OLDEST_COMPATIBLE_VERSION_MAJOR,
        kCPLD_IFC_OLDEST_COMPATIBLE_VERSION_MINOR,
        kCPLD_IFC_OLDEST_COMPATIBLE_VERSION_BUILD
      ),
      BuildVersion(
        kCPLD_IFC_CURRENT_VERSION_MAJOR,
        kCPLD_IFC_CURRENT_VERSION_MINOR,
        kCPLD_IFC_CURRENT_VERSION_BUILD
      )
    ) report "unexpected version_info output" severity error;

    -- check signature
    axiLiteReadRequest(std_logic_vector(to_unsigned(kBase+kSIGNATURE_REGISTER, 17)));
    checkAxiReadResponse(false, X"CB1D1FAC");

    -- write scratch req via AXI
    axiLiteWriteRequest(std_logic_vector(to_unsigned(kBase+kSCRATCH_REGISTER, 17)), X"0123ABCD");
    checkAxiWriteResponse(false);

    -- read scratch reg via app controlport interface using a timed command
    wait until falling_edge(radio_clk);
    app_ctrlport_req_rd <= '1';
    app_ctrlport_req_addr <= std_logic_vector(to_unsigned(kBase+kSCRATCH_REGISTER, 20));
    app_ctrlport_req_byte_en <= (others => '1');
    app_ctrlport_req_has_time <= '1';
    app_ctrlport_req_time <= std_logic_vector(unsigned(radio_time) + 100);
    wait until falling_edge(radio_clk);
    app_ctrlport_req_rd <= '0';
    app_ctrlport_req_addr <= (others => 'X');
    app_ctrlport_req_has_time <= '0';

    wait until (radio_time = app_ctrlport_req_time) or (app_ctrlport_resp_ack = '1') for 100 us;
    assert app_ctrlport_resp_ack = '0' report "command executed ahead of time" severity error;

    wait until app_ctrlport_resp_ack = '1' for 10 us;
    wait until falling_edge(radio_clk);
    assert app_ctrlport_resp_ack = '1' report "scratch register read timeout" severity error;
    assert app_ctrlport_resp_data = X"0123ABCD" report "scratch register content mismatch" severity error;
    assert app_ctrlport_resp_status = "00" report "scratch register read status incorrect" severity error;

    -- configure SPI clock divider
    axiLiteWriteRequest(std_logic_vector(to_unsigned(kBase+kMOTHERBOARD_CPLD_DIVIDER, 17)), std_logic_vector(to_unsigned(1, 32)));
    checkAxiWriteResponse(false);
    axiLiteWriteRequest(std_logic_vector(to_unsigned(kBase+kDAUGHTERBOARD_CPLD_DIVIDER, 17)), std_logic_vector(to_unsigned(3, 32)));
    checkAxiWriteResponse(false);

    -- test a bunch of read and writes towards MB and DBs
    for j in 1 to 3 loop
      for i in 0 to 20 loop

        -- start data transfer
        randomRequest := Rand.GetStdLogicVector(randomRequest'length);
        randomResponse := Rand.GetStdLogicVector(randomResponse'length);

        -- in case of write request
        if (randomRequest(randomRequest'high) = '1') then
          axiLiteWriteRequest(std_logic_vector(to_unsigned(j, 2)) & randomRequest(32+15-1 downto 32), randomRequest(31 downto 0));
          checkControlportRequest(true, randomRequest(32+15-1 downto 32), randomRequest(31 downto 0));

          if (j = 1) then
            assert ss = "00" report "incorrect slave select assignment (MB CPLD expected)" severity error;
          elsif (j = 2) then
            assert ss = "10" report "incorrect slave select assignment (DB 0 CPLD expected)" severity error;
          elsif (j = 3) then
            assert ss = "01" report "incorrect slave select assignment (DB 1 CPLD expected)" severity error;
          end if;

          issueControlportResponse(to_Boolean(randomResponse(randomResponse'high)), randomResponse(31 downto 0));
          checkAxiWriteResponse(to_Boolean(randomResponse(randomResponse'high)));
        else
          axiLiteReadRequest(std_logic_vector(to_unsigned(j, 2)) & randomRequest(32+15-1 downto 32));
          checkControlportRequest(false, randomRequest(32+15-1 downto 32), randomRequest(31 downto 0));

          issueControlportResponse(to_Boolean(randomResponse(randomResponse'high)), randomResponse(31 downto 0));
          checkAxiReadResponse(to_Boolean(randomResponse(randomResponse'high)), randomResponse(31 downto 0));
        end if;

      end loop;
    end loop;

    -- test LED status --> links got active
    qsfp1_led_link <= X"F";
    qsfp1_led_active <= X"0";
    qsfp0_led_link <= X"1";
    qsfp0_led_active <= X"0";

    -- change status twice but expect request only for latest status
    wait for 4*kPrcPer;
    qsfp1_led_active <= X"A";
    wait for 4*kPrcPer;
    qsfp1_led_active <= X"4";
    qsfp0_led_active <= X"1";

    -- check for two requests for links got active and only one for activity
    checkControlportRequest(true, std_logic_vector(to_unsigned(kPL_REGISTERS+kLED_REGISTER,15)), X"00000F01");
    checkControlportRequest(true, std_logic_vector(to_unsigned(kPL_REGISTERS+kLED_REGISTER,15)), X"00004F11");

    -- activate iPass forwarding
    axiLiteWriteRequest(std_logic_vector(to_unsigned(kBase+kIPASS_CONTROL, 17)), SetBit(kIPASS_ENABLE_TRANSFER));
    checkAxiWriteResponse(false);
    checkControlportRequest(true, std_logic_vector(to_unsigned(kBase+kCABLE_PRESENT_REG, 15)), Zeros(32));
    issueControlportResponse(false, Zeros(32));

    -- attach iPass cable and check update request
    ipass_present_n(0) <= '0';
    wait for 2*kPrcPer;
    checkControlportRequest(true, std_logic_vector(to_unsigned(kBase+kCABLE_PRESENT_REG, 15)), SetBit(kIPASS0_CABLE_PRESENT));
    issueControlportResponse(true, Zeros(32));
    -- check repetition on error
    checkControlportRequest(true, std_logic_vector(to_unsigned(kBase+kCABLE_PRESENT_REG, 15)), SetBit(kIPASS0_CABLE_PRESENT));
    issueControlportResponse(false, Zeros(32));

    -- test invalid addresses / access in each register map
    axiLiteWriteRequest(std_logic_vector(to_unsigned(kBase+kSIGNATURE_REGISTER, 17)), X"00000000");
    checkAxiWriteResponse(true);
    axiLiteReadRequest(std_logic_vector(to_unsigned(kBase+kSIGNATURE_REGISTER+1, 17)));
    checkAxiReadResponse(true, X"00000000");

    axiLiteReadRequest(std_logic_vector(to_unsigned(kBase+2, 17)));
    checkAxiReadResponse(true, X"00000000");

    -- random access to invalid address space above SPI control registers until 15 bit boundary
    for i in 0 to 100 loop
      axiLiteReadRequest(std_logic_vector(to_unsigned(Rand.GetNatural(2**15 - kBase - kBaseSize) + kBase + kBaseSize, 17)));
      checkAxiReadResponse(true, X"00000000");
    end loop;

    StopSim <= true;
    wait;
  end process;

end test;
--synopsys translate_on
