#!/usr/bin/python

from Bio import AlignIO
import argparse

import warnings
warnings.filterwarnings("ignore")

parser = argparse.ArgumentParser()
parser.add_argument("informat", help="input alignment format")
parser.add_argument("outformat", help="output alignment format")
parser.add_argument("infile", help="input filename")
parser.add_argument("outfile", help="output filename")

args = parser.parse_args()
informat = args.informat
outformat = args.outformat
infile = args.infile
outfile = args.outfile

input_handle = open(infile, "rU")
output_handle = open(outfile, "w")

alignments = AlignIO.parse(input_handle, informat)
AlignIO.write(alignments, output_handle, outformat)
 
output_handle.close()
input_handle.close()
