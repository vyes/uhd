Boot the board:

1. Open a UART console to the SCU.
  a. Open PuTTy; connect to COM5, 115200 baud. Example commands:
    > zynqmp boot       <<< reboots the device
    > zynqmp status     <<< prints some status info for the FPGA
    > reboot            <<< reboots the SCU, thereby resetting the FPGA to power-off
  b. Boot the RFSoC
    > zynqmp boot

2. Open a JTAG session to the FPGA. These steps will enable you to perform remote access
   to the device using SDK from another host. If you want to use SDK on this machine,
   simply open it and then skip to step 3.
  a. Open the program "Vivado HLS 2018.3 Command Prompt"
  b. Type `hw_server` to launch the hw manager. This step should end in a line that
     prints the server information... like "dprTest1:3121"... Leave this running.

3. Use SDK to initialize the PS and then the clocks.
  a. On the desired host (either this machine or remote), open SDK 2018.3. If you're
     working on a remote machine, follow the later half of these instructions
     https://www.xilinx.com/support/answers/64759.html or ask Jepson.
  b. In the SDK XSCT console, confirm you have access to the device, then target
     the correct device subsection
    % connect
    % targets    # should print out a list of ~12 targets
    % targets 4  # select the PSU target (could be either 4 or 5)
  c. Sync to uhddev:titanium-master
  d. Change the working directory in the SDK XSCT console to `<your root here>\uhddev\tools\zynq_driver`
  e. Start the reference and sample clocks via XSCT:
    % source ./utils.tcl
    % init
    % init_clocks <sample_clock_freq_hz, default is 3e9 if blank>


4. Load a bitfile (either through LV, or follow these instructions to load a .bin
   or .bit through XSCT):
  % fpga <path to bitfile, forward slashes only>

5. Start RF block
  % init_rf