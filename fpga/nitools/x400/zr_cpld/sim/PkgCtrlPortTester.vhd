--
-- Copyright 2020 Ettus Research, A National Instruments Company
--
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: PkgCtrlPortTester
-- Description:
--   Provides simple infrastructure to test CtrlPort registers
--

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.PkgNiSim.all;
  use work.PkgNiUtilities.all;
  use work.PkgProtected.all;
  use work.PkgMemTester.all;

library work;
  -- use work.PkgSerial.all;

package PkgCtrlPortTester is

  procedure CtrlPortRead( constant kOffset       : in  natural;
                          variable RegReadData   : out std_logic_vector;
                          variable RegStatus     : out std_logic_vector;
                          variable RegAck        : out std_logic;
                          constant kThreadId     : in  natural := 0);
  procedure CtrlPortWrite( constant kOffset       : in natural;
                           constant kRegWriteData : in std_logic_vector;
                           constant kThreadId     : in  natural := 0);

  constant kRegisterSize : integer := 32;

  -- Test toggling of bit and reading it.
  procedure TestCtrlPortReg (
                             constant kRegName        : in string;
                             constant kRegisterOffset : in natural;
                             constant kRegisterMask   : in std_logic_vector(kRegisterSize-1 downto 0);
                             signal   RegisterOutput  : in std_logic_vector(kRegisterSize-1 downto 0);
                             constant kCheckRegOutput : in boolean;
                             constant kWaitTimeout    : in time
                           );

  procedure CheckExpectedCtrlPortRead(
                          constant kOffset       : in  natural;
                          constant kExpectedData : in  std_logic_vector(kRegisterSize-1 downto 0);
                          constant kThreadId     : in  natural := 0);

end package;

package body PkgCtrlPortTester is

  --Wrapper on the internal function for register reads and writes. All data
  --is kept as descending, so if the input is ascending it is reversed.
  procedure CtrlPortRead(constant kOffset       : in  natural;
                         variable RegReadData   : out std_logic_vector;
                         variable RegStatus     : out std_logic_vector;
                         variable RegAck        : out std_logic;
                         constant kThreadId     : in  natural := 0) is
    -- Add 39 downto 0 for extra byte to account for 3 extrabits from RegStatus and RegAck
    variable RegReadDataLcl : std_logic_vector(39 downto 0) := (others=>'0');
  begin
    --send an extra byte to read the status and ack bits
    regread(kOffset, RegReadDataLcl, kThreadId, false, kRegDefaultDataWidth + kByteWidth);

    RegReadData := RegReadDataLcl(31 downto 0);
    RegStatus   := RegREadDataLcl(33 downto 32);
    RegAck      := RegREadDataLcl(34);

  end procedure CtrlPortRead;

  -- This procedure simplifies the code required to read an verify the value of a register.
  procedure CheckExpectedCtrlPortRead(constant kOffset       : in  natural;
                                      constant kExpectedData : in  std_logic_vector(kRegisterSize-1 downto 0);
                                      constant kThreadId     : in  natural := 0) is
    --vhook_nowarn RegStatus RegAck
    variable RegStatus     : std_logic_vector(1 downto 0);
    variable RegAck        : std_logic;
    variable RegReadData   : std_logic_vector(kRegisterSize-1 downto 0);
  begin
    CtrlPortRead(kOffset, RegReadData, RegStatus, RegAck, kThreadId);

    assert RegReadData = kExpectedData
      report "Register read returned incorrect value"
      severity error;

  end procedure CheckExpectedCtrlPortRead;

  --Ack and status checked in CtrlBusModel
  procedure CtrlPortWrite( constant kOffset       : in natural;
                           constant kRegWriteData : in std_logic_vector;
                           constant kThreadId     : in  natural := 0) is
  begin
    regwrite(kOffset, kRegWriteData, kThreadId);
  end procedure CtrlPortWrite;

  --Test toggling of bit and reading it.
  procedure TestCtrlPortReg (
    constant kRegName        : in string;
    constant kRegisterOffset : in natural;
    constant kRegisterMask   : in std_logic_vector(kRegisterSize-1 downto 0);
    signal   RegisterOutput  : in std_logic_vector(kRegisterSize-1 downto 0);
    constant kCheckRegOutput : in boolean;
    constant kWaitTimeout    : in time)
  is
    variable ReadData          : std_logic_vector(31 downto 0) := (others => 'X');
    variable Status            : std_logic_vector(1  downto 0) := (others => 'X');
    variable Ack               : std_logic                     := 'X';
    variable WriteData         : std_logic_vector(31 downto 0) := (others => '0');
    variable RegisterPrevValue : std_logic_vector(kRegisterSize-1 downto 0) := (others => '0');
    variable RegisterNewValue  : std_logic_vector(kRegisterSize-1 downto 0) := (others => '0');
  begin
      --This loop cycles through and tests each bit
      for k in 0 to kRegisterSize-1 loop
        --only test write able registers
        if kRegisterMask(k) = '1' then
            -- This loop will test the values Low-High-Low
          for i in 0 to 2 loop
            -- Store the previous value of the register.
            RegisterPrevValue := RegisterOutput;

            --read previous bit to check against next write
            CtrlPortRead(kRegisterOffset, ReadData, Status, Ack);
            WriteData := ReadData;

            assert Status = "00"
              report "Ctrl port write status error " & kRegName
              severity error;

            -- Write bit: first 0, then 1 then 0
            WriteData(k) := to_stdlogic(i = 1);
            CtrlPortWrite(kRegisterOffset, WriteData);

            --Assert kCheckRegOutput if only testing registers and not physical signals
            if kCheckRegOutput then
              -- Output bit expected to change before timeout.
              if (RegisterOutput(k) /= to_stdlogic(i = 1)) then
                wait until (RegisterOutput(k) = to_stdlogic(i = 1)) for kWaitTimeout;
              end if;

              -- Store the new value of the register.
              RegisterNewValue := RegisterOutput;

              -- Check that only the desired bit changed.
              for BitIndex in 0 to kRegisterSize-1 loop
                if BitIndex = k then
                  assert RegisterNewValue(k) = WriteData(k)
                    report "? " & kRegName & image(k) & " did not change when expected."
                    severity error;
                else
                  assert RegisterNewValue(BitIndex) = RegisterPrevValue(BitIndex)
                    report "? " & kRegName & image(k) & " changed when it was not expected. New value: " &
                           image(RegisterNewValue(BitIndex)) & " previous value:" &
                           image(RegisterPrevValue(BitIndex))
                    severity error;
                end if;
              end loop;

            end if;

            -- Read bit back through RegPort and assert the masked data.
            CtrlPortRead(kRegisterOffset, ReadData, status, Ack);
            assert WriteData = ReadData
              report "The value read through RegBus for " & kRegName & " is incorrect." &
                     "expected: " & heximage(WriteData) & " Received: " & heximage(ReadData)
              severity error;

            assert Ack = '1'
              report "Ctrl port Ack status error " & kRegName
              severity error;

            assert Status = "00"
              report "Ctrl port read status error " & kRegName
              severity error;

          end loop;

        end if;

      end loop;

  end procedure;


end package body;
