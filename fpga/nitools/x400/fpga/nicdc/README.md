# Questa CDC/RDC Analysis for FPGA

Download and install Questa CDC/Formal 2021.1. Download these files:

- `QFT_V2021.1_CDC_Formal.mis`
- `QFT_V2021.1_FPGA_LIBS_Xilinx.mis`
- `questa_formal-win64-2021.1.exe`

Next, run `questa_formal-win64-2021.1.exe` to install it along with the CDC
and Xilinx FPGA libraries.

To run the CDC/RDC analysis, run hwsetup, change directory to `nicdc/` then run
`qverify`, as shown below, to run the tools and generate the reports:

```
cd fpga\nitools\x400\fpga\nicdc
hwsetup
make
```

Running `make` will run the `qverify -c -licq -do nicdc.tcl` command but also
has options to clean the output in case things go wrong. Run `make help` for
more info.

See the following report files:

- `nicdc.rpt`: NI CDC report summary
- `qverify.log`: Complete Questa CDC output log
- `cdc/cdc_detail.rpt`: CDC report details
- `cdc/cdc_msg.rpt`: CDC message report
- `rdc/rdc_detail.rpt`: RDC report details
- `rdc/rdc_msg.rpt`: RDC message report
