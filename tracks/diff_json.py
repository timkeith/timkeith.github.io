#!/usr/bin/env python

# Compare two json files: normalize and then diff

import sys
import json
from tempfile import NamedTemporaryFile
import subprocess

if len(sys.argv) != 3:
  print 'Usage: {0} <json-file> <json-file>'.format(sys.argv[0])
  exit(1)

def main():
  file1 = sys.argv[1]
  file2 = sys.argv[2]
  with NamedTemporaryFile(suffix='.json') as temp1, \
      NamedTemporaryFile(suffix='.json') as temp2:
    normalize_json(file1, temp1)
    normalize_json(file2, temp2)
    subprocess.call(['diff', temp1.name, temp2.name])

# Write json from path 'inFile' to file 'out'.
# Normalize by formatting and sorting keys
def normalize_json(inFile, out):
  with open(inFile) as inf:
    data = json.load(inf)
    json.dump(data, out, indent=1, sort_keys=True)
    out.flush()

main()
