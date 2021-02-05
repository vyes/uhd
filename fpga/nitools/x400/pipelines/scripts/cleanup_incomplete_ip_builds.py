#!/usr/bin/env python3

import argparse
import os
import shutil

# argument parsing
parser = argparse.ArgumentParser(description="This script removes all directories where the .build_lock file still exists")
parser.add_argument('--directory', '-d', required=True, help='directory to search for lock files (recursively)')
args = parser.parse_args()

# search .build_lock files
lockFiles = []
for root, dirs, files in os.walk(args.directory):
  for file in files:
    if file == ".build_lock":
      lockFiles.append(os.path.join(root, file))

# remove all directories containing lock files
for lockFile in lockFiles:
  dirPath = os.path.dirname(lockFile)
  print("delete " + dirPath)
  shutil.rmtree(dirPath)
