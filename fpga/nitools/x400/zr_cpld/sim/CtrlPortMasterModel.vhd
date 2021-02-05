--
-- Copyright 2020 Ettus Research, A National Instruments Company
--
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: CtrlPortMasterModel
-- Description:
--   The following file is the BFM for the control bus. Using underlying queues
-- found in the PkgMemTester file it processes reads and writes. It is designed
-- to be used in conjuction with a testbench that calls RegRead() and RegWrite()
-- functions found in the PkgMemTester.
--   Additonal feature include multi-theading (setup with the ThreadId generic),
-- and the ability to manipulate the number of bytes and byte alignment used by
-- the address filed in the RegPortIn_t record. For more details see the theory
-- of operation and the code herein.
--
--

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.PkgNiSim.all;
  use work.PkgNiUtilities.all;
  use work.PkgMemTester.all;

entity CtrlPortMasterModel is
  generic(

    --The queue structure and model support multi-threading. If multi-threading
    --is needed (meaning a CtrlRegRead() or CtrlRegWrite() call includes the thread),
    --then this generic can be set to the thread number. If multi-threading is
    --not needed the thread defaults to 0 and an assignment of open can be used
    --on this generic to make sure the default value works correctly.
    kThreadId : in natural := 0;

    --Per the specification the register port by default pulses the data input
    --and address with register read and write assertion. However, register
    --access files, especially low level items, may assume that data input and
    --address are held to the same value once updated. This generic is used to
    --enable or disable this feature. The default value is true as most register
    --access files require a hold. If true works, this can be set to open.
    kHoldAccess : in boolean := true;

    --Number of ctrlport_clk cycles to wait until returning a timeout error to the master
    kClkCycleTimeout  : in natural := 1000

  );
  port(

    --Reset and clock control. This is designed to either be a simulation
    --specific control or the same reset and clock used by the port that
    --connects to the control port. All register operations are kept
    --synchronous to ctrlport_clk, making this model acceptable for low level
    --testbenching of register access files.
    ctrlport_rst : in boolean;
    ctrlport_clk : in std_logic;

    --All of the movement of register accesses is through a control port.
    --These signals should be in the ctrlport_clk domain.
     m_ctrlport_req_wr      : out std_logic;
     m_ctrlport_req_rd      : out std_logic;
     m_ctrlport_req_addr    : out std_logic_vector(19 downto 0);
     m_ctrlport_req_data    : out std_logic_vector(31 downto 0);

     m_ctrlport_resp_ack    : in  std_logic;
     m_ctrlport_resp_status : in  std_logic_vector(1  downto 0);
     m_ctrlport_resp_data   : in  std_logic_vector(31 downto 0)
  );
end CtrlPortMasterModel;

architecture behav of CtrlPortMasterModel is

  --Local signal setup, for details see where used.
  signal ctrlport_clk_dlyd       : std_logic := '0';
  signal rMemId           : natural := 0;
  signal rTimeoutCounter  : natural := 0;
  signal rHoldOffBus      : boolean := false;

  signal m_ctrlport_req_wr_lcl    : std_logic;
  signal m_ctrlport_req_rd_lcl    : std_logic;
  signal m_ctrlport_req_addr_lcl  : std_logic_vector(19 downto 0);
  signal m_ctrlport_req_data_lcl  : std_logic_vector(31 downto 0);

  -- PkgScoreboard
  constant kStatusCoverPoint : string := behav'path_name & "ReponseStatus";

  --vhook_sigstart
  --vhook_sigend

begin

  --vhook_nowarn ctrlport_clk

  -- Setup status check as restricted coverpoint, which should not be hit during
  -- normal operation.
  gScoreboard.RegisterRestrictedCover(kStatusCoverPoint);

  --Create a delayed version of register clock to drive RegPortIn. For low level
  --testbenches this prevents any delta cycle issues.
  ctrlport_clk_dlyd <= ctrlport_clk'delayed;

  --Internally this operates to monitor for a memory request from a mem req
  --queue. All data types with the exception of RegPortIn are found in Pkg-
  --MemTester. For more details see that file.
  CtrlPortInterface: process(ctrlport_rst, ctrlport_clk_dlyd)
    variable CtrlPortCurrReq : MemTesterReq_t := kMemTesterReqZero;
  begin

    --On reset clear the ID and register port and reinit the memory request.
    if ctrlport_rst then
      CtrlPortCurrReq     := kMemTesterReqZero;
      rMemId              <= 0;

      m_ctrlport_req_wr_lcl   <= '0';
      m_ctrlport_req_rd_lcl   <= '0';
      m_ctrlport_req_addr_lcl <= (others =>'0');
      m_ctrlport_req_data_lcl <= (others =>'0');

      rTimeoutCounter         <= 0;
      rHoldOffBus             <= false;

    elsif rising_edge(ctrlport_clk_dlyd) then

      --Always clear the register input port. Often low level testbenches assume
      --that address and data are held after the register port is updated. If
      --that is the case as indicated by the generice, persist those values. This
      --signal assignment also has the side effect of clearing register read or
      --write, setting it up as a strict pulse if asserted the cycle prior.

      m_ctrlport_req_wr_lcl   <= '0';
      m_ctrlport_req_rd_lcl   <= '0';
      m_ctrlport_req_addr_lcl <= (others =>'0');
      m_ctrlport_req_data_lcl <= (others =>'0');

      if kHoldAccess then
        m_ctrlport_req_addr_lcl <= m_ctrlport_req_addr_lcl;
        m_ctrlport_req_data_lcl <= m_ctrlport_req_data_lcl;

      end if;

      --Monitor for any register operation. This is accomplished using the peek
      --function, IsMem-Pending() from PkgMemTester. When true there is a req
      --on the queue forthis thread so dequeue it with GetMemRequest().
      if not rHoldOffBus then
        if IsMemPending( ThreadId => kThreadId, IsRegOp => true ) then
          CtrlPortCurrReq       := GetMemRequest( ThreadId => kThreadId );
          rMemId                <= CtrlPortCurrReq.MemId;

          if CtrlPortCurrReq.MemOp = DutMemWt then
            m_ctrlport_req_wr_lcl <= '1';
          end if;
          if CtrlPortCurrReq.MemOp = DutMemRd then
            m_ctrlport_req_rd_lcl <= '1';
          end if;

          m_ctrlport_req_addr_lcl <= std_logic_vector(to_unsigned(CtrlPortCurrReq.MemAddr, m_ctrlport_req_addr_lcl'length));
          m_ctrlport_req_data_lcl <= CtrlPortCurrReq.MemData(m_ctrlport_req_data_lcl'range);

          rHoldOffBus <= true;

        end if;
      --Wait for an ack response or timeout
      else
        if m_ctrlport_resp_ack = '1' or rTimeoutCounter > kClkCycleTimeout then
          rHoldOffBus <= false;
          rTimeoutCounter <= 0;
        else
          rTimeoutCounter <= rTimeOutCounter + 1;
        end if;

      end if;
    end if;
  end process CtrlPortInterface;

  m_ctrlport_req_wr   <= m_ctrlport_req_wr_lcl;
  m_ctrlport_req_rd   <= m_ctrlport_req_rd_lcl;
  m_ctrlport_req_addr <= m_ctrlport_req_addr_lcl;
  m_ctrlport_req_data <= m_ctrlport_req_data_lcl;

  --vhook_nowarn rMemId
  --vhook_nowarn *RespData

  --This process looks for a register read or write pulse and then waits for
  --the register operation to complete (monitoring register ready). All data
  --types with the exception of RegPortIn and RegPortOut are found in PkgMem-
  --Tester. For more details see that file.
  CtrlPortAckInterface: process
    variable RespData : std_logic_vector((kRegMaxDataWidth-1) downto 0);
  begin

    --Wait for a write or read pulse.
    wait until rising_edge(m_ctrlport_req_wr_lcl) or rising_edge(m_ctrlport_req_rd_lcl);

    RespData := (others=>'0');

    --Wait for register ready to assert or reset. On a data valid store
    --the data output for completion. Once ready asserts the register
    --operation is complete, transition out of the loop. There is no
    --timeout here as the timeout is handled in PkgMemTester with the
    --testbench call to RegWrite() or RegRead().
    while (not ctrlport_rst) loop
      wait until falling_edge(ctrlport_clk_dlyd);
      if m_ctrlport_resp_ack then
        RespData := (others=>'0');
        RespData(m_ctrlport_resp_data'range) := m_ctrlport_resp_data;
        RespData(33 downto 32)               := m_ctrlport_resp_status;
        RespData(34)                         := m_ctrlport_resp_ack;

        exit;
      end if;
    end loop;

    if m_ctrlport_resp_status /= "00" then
      gScoreboard.NoteCover(kStatusCoverPoint,
        "CtrlPort register access status error. Error code: " & heximage(m_ctrlport_resp_status)
        );
    end if;

    --If the above loop completed due to register ready asserting, the
    --operation is complete, use the SetMemDone() function from PkgMem-
    --Tester to enqueue the completion onto the ack queue. Pass in the
    --correct thread ID, memory ID, and data.
    if (not ctrlport_rst) then
      SetMemDone( ThreadId => kThreadId,
                  MemId    => rMemId,
                  MemData  => RespData );
    end if;

  end process CtrlPortAckInterface;

end behav;
