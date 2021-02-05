---------------------------------------------------------------------
--
-- Copyright 2019 Ettus Research, A National Instruments Brand
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: rf_reset_controller.vhd
--
-- Purpose:
--
-- Control RFDC, ADC, and DAC resets.
--
----------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.PkgRFDC_REGS_REGMAP.all;

entity rf_reset_controller is
  port(
    -- Lots and lots of clocks. Config clock is async to all the others.
    ConfigClk            : in std_logic;
    DataClk              : in std_logic;
    PllRefClk            : in std_logic;
    RfClk                : in std_logic;
    RfClk2x              : in std_logic;
    DataClk2x            : in std_logic;

    -- Master resets from the Radio
    dAdcResetPulse       : in std_logic;
    dDacResetPulse       : in std_logic;

    -- ADC Resets
    dAdcDataOutReset_n   : out std_logic;
    r2AdcFirReset_n      : out std_logic;
    rAdcRfdcAxiReset_n   : out std_logic;
    rAdcEnableData       : out std_logic;
    rAdcGearboxReset_n   : out std_logic;

    -- DAC Resets
    dDacDataInReset_n    : out std_logic;
    r2DacFirReset_n      : out std_logic;
    d2DacFirReset_n      : out std_logic;
    rDacRfdcAxiReset_n   : out std_logic;
    rDacGearboxReset_n   : out std_logic;

    -- SW Control and Status
    -- Control to initiate resets to RFDC and decimation block including the
    -- gearboxes. The reset status is a sticky status of both ADC and DAC.
    cSoftwareControl     : in std_logic_vector(31 downto 0);
    cSoftwareStatus      : out std_logic_vector(31 downto 0)
  );
end rf_reset_controller;


architecture RTL of rf_reset_controller is

  -- POR value for all resets are high.
  signal cTriggerAdcReset       : std_logic := '1';
  signal cTriggerAdcResetDlyd   : std_logic := '1';
  signal cTriggerDacReset       : std_logic := '1';
  signal cTriggerDacResetDlyd   : std_logic := '1';

  signal dTriggerAdcReset_ms  : std_logic := '1';
  signal dTriggerAdcReset     : std_logic := '1';
  signal dTriggerDacReset_ms  : std_logic := '1';
  signal dTriggerDacReset     : std_logic := '1';

  -- POR value of all reset done signals are set to low.
  signal cTriggerAdcResetDone_ms     : std_logic := '0';
  signal cTriggerAdcResetDone        : std_logic := '0';
  signal cAdcResetDoneSticky         : std_logic := '0';
  signal cTriggerDacResetDone_ms     : std_logic := '0';
  signal cTriggerDacResetDone        : std_logic := '0';
  signal cDacResetDoneSticky         : std_logic := '0';

  attribute ASYNC_REG : string;
  attribute ASYNC_REG of dTriggerAdcReset          : signal is "TRUE";
  attribute ASYNC_REG of dTriggerDacReset          : signal is "TRUE";
  attribute ASYNC_REG of cTriggerAdcResetDone      : signal is "TRUE";
  attribute ASYNC_REG of cTriggerDacResetDone      : signal is "TRUE";
  attribute ASYNC_REG of dTriggerAdcReset_ms       : signal is "TRUE";
  attribute ASYNC_REG of dTriggerDacReset_ms       : signal is "TRUE";
  attribute ASYNC_REG of cTriggerAdcResetDone_ms   : signal is "TRUE";
  attribute ASYNC_REG of cTriggerDacResetDone_ms   : signal is "TRUE";

begin

  -- rAdcEnableData is set to '1' as we don't control the flow of rx data
  rAdcEnableData <= '1';

  cTriggerAdcReset <= cSoftwareControl(kADC_RESET);
  cTriggerDacReset <= cSoftwareControl(kDAC_RESET);

  cSoftwareStatus <= (
                     kADC_SEQ_DONE   => cAdcResetDoneSticky,
                     kDAC_SEQ_DONE   => cDacResetDoneSticky,
                     others => '0'
                     );


  -- High-Level Resets using ConfigClk : --------------------------------------
  -- Pass the master FSM reset around to the other clock domains and then
  -- return them back to the ConfigClk domain. This is also a handy way to
  -- prove all your clocks are toggling to some extent.
  -- --------------------------------------------------------------------------
  SeqResetDataClk : process(DataClk)
  begin
    if rising_edge(DataClk) then
      -- double-syncs have no sync reset!
      dTriggerAdcReset_ms  <= cTriggerAdcReset;
      dTriggerAdcReset     <= dTriggerAdcReset_ms;
      dTriggerDacReset_ms  <= cTriggerDacReset;
      dTriggerDacReset     <= dTriggerDacReset_ms;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Reset sequence done status
  -----------------------------------------------------------------------------

  -- Now back to ConfigClk! We provide the status for all software controlled
  -- resets. We move the signal from ConfigClk to DataClk domain and move it
  -- back to ConfigClk domain. This just proves that DataClk is toggling and
  -- the reset requested by software is sampled in the DataClk.
  SeqResetDone : process(ConfigClk)
  begin
    if rising_edge(ConfigClk) then
      -- double-syncs have no sync reset!
      cTriggerAdcResetDone_ms   <= dTriggerAdcReset;
      cTriggerAdcResetDone      <= cTriggerAdcResetDone_ms;
      cTriggerDacResetDone_ms   <= dTriggerDacReset;
      cTriggerDacResetDone      <= cTriggerDacResetDone_ms;
    end if;
  end process;

  -- ADC reset done
  SwAdcResetDone: process(ConfigClk)
  begin
    if rising_edge(ConfigClk) then
      cTriggerAdcResetDlyd <= cTriggerAdcReset;
      -- De-assert reset status on the rising edge of SW ADC reset.
      if cTriggerAdcReset = '1' and cTriggerAdcResetDlyd = '0' then
        cAdcResetDoneSticky <= '0';
      -- Assert and hold the ADC reset status on ADC reset strobe
      elsif cTriggerAdcResetDone = '1' then
        cAdcResetDoneSticky <= '1';
      end if;
    end if;
  end process SwAdcResetDone;

  -- DAC reset done
  SwDacResetDone: process(ConfigClk)
  begin
    if rising_edge(ConfigClk) then
      cTriggerDacResetDlyd <= cTriggerDacReset;
      -- De-assert reset status on the rising edge of SW DAC reset.
      if cTriggerDacReset = '1' and cTriggerDacResetDlyd = '0' then
        cDacResetDoneSticky <= '0';
      -- Assert and hold the DAC reset status on DAC reset strobe
      elsif cTriggerDacResetDone = '1' then
        cDacResetDoneSticky <= '1';
      end if;
    end if;
  end process SwDacResetDone;

  --vhook_e rf_reset AdcResets
  --vhook_a dTimedReset dAdcResetPulse
  --vhook_a dSwReset    dTriggerAdcReset
  --vhook_a dReset_n    dAdcDataOutReset_n
  --vhook_a r2Reset_n   r2AdcFirReset_n
  --vhook_a rAxiReset_n rAdcRfdcAxiReset_n
  --vhook_a rReset_n    rAdcGearboxReset_n
  --vhook_a d2Reset_n   open
  AdcResets: entity work.rf_reset (RTL)
    port map (
      DataClk     => DataClk,             --in  std_logic
      PllRefClk   => PllRefClk,           --in  std_logic
      RfClk       => RfClk,               --in  std_logic
      RfClk2x     => RfClk2x,             --in  std_logic
      DataClk2x   => DataClk2x,           --in  std_logic
      dTimedReset => dAdcResetPulse,      --in  std_logic
      dSwReset    => dTriggerAdcReset,    --in  std_logic
      dReset_n    => dAdcDataOutReset_n,  --out std_logic:='0'
      d2Reset_n   => open,                --out std_logic:='0'
      r2Reset_n   => r2AdcFirReset_n,     --out std_logic:='0'
      rAxiReset_n => rAdcRfdcAxiReset_n,  --out std_logic:='0'
      rReset_n    => rAdcGearboxReset_n); --out std_logic:='0'

  --vhook_e rf_reset DacResets
  --vhook_a dTimedReset dDacResetPulse
  --vhook_a dSwReset    dTriggerDacReset
  --vhook_a dReset_n    dDacDataInReset_n
  --vhook_a r2Reset_n   r2DacFirReset_n
  --vhook_a rAxiReset_n rDacRfdcAxiReset_n
  --vhook_a rReset_n    rDacGearboxReset_n
  --vhook_a d2Reset_n   d2DacFirReset_n
  DacResets: entity work.rf_reset (RTL)
    port map (
      DataClk     => DataClk,             --in  std_logic
      PllRefClk   => PllRefClk,           --in  std_logic
      RfClk       => RfClk,               --in  std_logic
      RfClk2x     => RfClk2x,             --in  std_logic
      DataClk2x   => DataClk2x,           --in  std_logic
      dTimedReset => dDacResetPulse,      --in  std_logic
      dSwReset    => dTriggerDacReset,    --in  std_logic
      dReset_n    => dDacDataInReset_n,   --out std_logic:='0'
      d2Reset_n   => d2DacFirReset_n,     --out std_logic:='0'
      r2Reset_n   => r2DacFirReset_n,     --out std_logic:='0'
      rAxiReset_n => rDacRfdcAxiReset_n,  --out std_logic:='0'
      rReset_n    => rDacGearboxReset_n); --out std_logic:='0'

end RTL;
