#
# Copyright 2020 Ettus Research, a National Instruments Brand
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#
# Module: replace_HDL_header
#
# Description:
#   run 'python replace_HDL_header.py -h' to see help
#

import os
import argparse
import pathlib
import datetime
import re

# argument parsing
parser = argparse.ArgumentParser(description="""Replaces any kind of header by the default OSS header.
All consecutive comment lines from the beginning of the file are considered part of the header.""")
parser.add_argument('--inputFilePath', '-i', required=True, help='original HDL file')
parser.add_argument('--outputFilePath', '-o', required=False, help='modified HDL file (will be overwritten if exists)')
args = parser.parse_args()

# store arguments into variables
inputFilePath = args.inputFilePath
outputFilePath = args.outputFilePath

if not os.path.exists(inputFilePath):
  print("The input file %s does not exist!" % inputFilePath)
  sys.exit(1)

# determine comment string
pathObject = pathlib.Path(inputFilePath)
fileExtension = pathObject.suffix
# VHDL
if fileExtension in ['.vhd', '.vhdl']:
  commentString = "--"
# others are assumed to be Verilog
else:
  commentString = "//"

## new header
newHeader = """%
% Copyright {} Ettus Research, a National Instruments Brand
%
% SPDX-License-Identifier: LGPL-3.0-or-later
%
% Module: {}
%
% Description:
%
%   This is an automatically generated file.
%   Do not modify this file directly!
%
""".format(datetime.datetime.now().year, pathObject.stem)

# add comment string to each comment line
newHeader = re.sub("^(%)", commentString, newHeader, flags=re.MULTILINE)

# copy file without header
with open(inputFilePath, 'r') as inputFile:
  with open(outputFilePath, 'w') as outputFile:
    # insert new header
    outputFile.write(newHeader)
    outputFile.write('\n')

    # scan through lines
    header = True
    for line in inputFile:
      # update header status
      if header:
        header = line.strip().startswith(commentString)

      # copy lines only outside of the header
      if not header:
        outputFile.write(line)
