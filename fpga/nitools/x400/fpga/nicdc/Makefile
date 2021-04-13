nicdc:  ##Run the CDC/RDC analsysis check (Default target)
	qverify -c -licq -do nicdc.tcl

clean:  ##Clean up all CDC/RDC run outputs.
	@echo "Cleaning CDC/RDC results..."
	@rm -rf .qverify
	@rm -rf cdc
	@rm -rf rdc
	@rm -rf scripts
	@rm -rf work
	@rm -f .qverify_ui_local_prefs
	@rm -f modelsim.ini
	@rm -f $(wildcard *.rpt)
	@rm -f $(wildcard *.log)
	@rm -f transcript

help:   ##Show this help message.
	@grep -h "##" Makefile | grep -v "\"##\"" | sed -e 's/\\$$//' | sed -e 's/##//'
