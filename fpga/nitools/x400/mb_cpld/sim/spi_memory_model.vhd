--
-- Copyright 2019 Ettus Research, A National Instruments Company
--
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: spi_memory_model
-- Description:
-- SPI slave with memory functionality as simulation model supports
-- CPHA = CPOL = 0 mode. All transmissions are done MSB first.
--
-- The transmit data format is as follows:
-- 1 bit write (write = 1, read=0)
-- 7 bit address
-- 8 bit data
--
-- Response format:
-- 8 bit unique id
-- 8 bit memory content based on request address

--synopsys translate_off
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work;
  use work.PkgNiSim.all;
  use work.PkgNiUtilities.all;

entity spi_memory_model is
generic (
  kUniqueId : std_logic_vector(7 downto 0)
);
port (
  sclk : in  std_logic;
  mosi : in  std_logic;
  miso : out std_logic;
  cs_n : in  std_logic;

  receivedData : out std_logic_vector(15 downto 0)
);
end spi_memory_model;

architecture sim of spi_memory_model is

  -- internal memory
  type tMemory is array (0 to 127) of std_logic_vector(7 downto 0);
  signal sMemory : tMemory := (others => (others => '0'));

  -- buffers
  signal sReceiveBuffer : std_logic_vector(15 downto 0) := (others => '0');
  signal sTransmitBuffer : std_logic_vector(15 downto 0) := kUniqueId & X"00";

  -- transmission counter
  signal sBitCounter : unsigned(3 downto 0) := (others => '0');

begin

receivedData <= sReceiveBuffer;
miso <= 'Z' when cs_n = '1' else sTransmitBuffer(15-to_integer(sBitCounter));

spiReceiver : process (sclk)
begin
  if rising_edge(sclk) then
    sReceiveBuffer <= sReceiveBuffer(sReceiveBuffer'left-1 downto 0) & mosi;
  end if;
end process spiReceiver;

spiTransmitter : process (sclk, cs_n)
begin
  if cs_n = '1' then
    sBitCounter <= (others => '0');
  elsif falling_edge(sclk) then
    sBitCounter <= sBitCounter + 1;
  end if;
end process spiTransmitter;

spiMemory : process (sclk)
begin
  if falling_edge(sclk) then
    -- read memory
    if sBitCounter = 7 then
      sTransmitBuffer(7 downto 0) <= sMemory(to_integer(unsigned(sReceiveBuffer(6 downto 0))));
    elsif sBitCounter = 15 then
      -- write operation
      if sReceiveBuffer(15) = '1' then
        sMemory(to_integer(unsigned(sReceiveBuffer(14 downto 8)))) <= sReceiveBuffer(7 downto 0);
      end if;
    end if;
  end if;
end process spiMemory;

end sim;
--synopsys translate_on