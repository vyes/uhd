---------------------------------------------------------------------
--
-- Copyright 2019 Ettus Research, A National Instruments Brand
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: tb_capture_sysref.v
--
-- Purpose:
--
-- testbench, self-checking.
--
----------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tb_capture_sysref is
end tb_capture_sysref;


architecture RTL of tb_capture_sysref is

  component capture_sysref
    port (
      pll_ref_clk     : in  std_logic;
      rfdc_clk        : in  std_logic;
      sysref_in       : in  std_logic;
      enable_rclk     : in  std_logic;
      sysref_out_pclk : out std_logic;
      sysref_out_rclk : out std_logic);
  end component;

  --vhook_sigstart
  signal enable_rclk: std_logic := '0';
  signal sysref_out_pclk: std_logic := '0';
  signal sysref_out_rclk: std_logic := '0';
  --vhook_sigend

  signal SysrefDly, SysrefDlyDly, rSysref : std_logic := '0';

  signal StopSim : boolean;
  constant kPerPRC : time := 30 ns;
  constant kPerRF  : time := 10 ns;
  constant kPerSR  : time := 300 ns;

  signal sysref_in: std_logic := '0';
  signal PllRefClk : std_logic := '1';
  signal RfdcClk : std_logic := '1';

  procedure ClkWait(X : positive := 1) is
  begin
    for i in 1 to X loop
      wait until rising_edge(PllRefClk);
    end loop;
  end procedure ClkWait;

begin

  PllRefClk <= not PllRefClk after kPerPRC/2 when not StopSim else '0';
  RfdcClk   <= not RfdcClk   after kPerRF/2  when not StopSim else '0';

  process(PllRefClk)
    variable count : integer := 1;
  begin
    if rising_edge(PllRefClk) then
      count := count +1;
      if count = 10 then
        sysref_in <= not sysref_in;
        count := 1;
      end if;
    end if;
  end process;

  --vhook   capture_sysref
  --vhook_a pll_ref_clk PllRefClk
  --vhook_a rfdc_clk    RfdcClk
  capture_sysrefx: capture_sysref
    port map (
      pll_ref_clk     => PllRefClk,        --in  wire
      rfdc_clk        => RfdcClk,          --in  wire
      sysref_in       => sysref_in,        --in  wire
      enable_rclk     => enable_rclk,      --in  wire
      sysref_out_pclk => sysref_out_pclk,  --out wire
      sysref_out_rclk => sysref_out_rclk); --out wire


  main: process
  begin
    enable_rclk <= '1';
    ClkWait(100);
    wait until falling_edge(sysref_out_rclk);
    ClkWait;
    wait until falling_edge(RfdcClk);
    enable_rclk <= '0';
    ClkWait(100);
    wait until falling_edge(RfdcClk);
    enable_rclk <= '1';
    ClkWait(100);

    StopSim <= true;
    wait;
  end process;


  checker_pllclk: process(PllRefClk)
  begin
    if falling_edge(PllRefClk) then
      SysrefDly    <= sysref_in;
      SysrefDlyDly <= SysrefDly;
      assert SysrefDlyDly = sysref_out_pclk
        report "SYSREF incorrectly captured in the PllRefClk domain"
        severity error;
    end if;
  end process;

  checker_RfdcClk: process(RfdcClk)
  begin
    if falling_edge(RfdcClk) then
      rSysref    <= sysref_out_pclk;
      assert (rSysref = sysref_out_rclk) or (enable_rclk = '0')
        report "SYSREF incorrectly captured in the RfdcClk domain."
        severity error;
    end if;
  end process;


end RTL;
