#!/usr/bin/ruby
# encoding: utf-8
#
#  untitled.rb
#
#  Created by Dan MacLean (TSL) on 2013-09-30.
#  Copyright (c). All rights reserved.
#
require 'pp'
require 'json'
require 'csv'
require 'bio'
require 'barmcakes'

def get_coords fasta
  fasta.definition =~ /(Cf746836_TGAC_s1v1_scaffold_\d+)_pep.*\s\[(\d+)\s-\s(\d+)\]\s+--HMM=(\d\.\d+)\s+--NNCleavageSite=(\d+)/
  puts [$1,$2,$3].join("\t")
  {
    :contig => $1,
    :sequence => fasta.seq,
    :id => fasta.entry_id,
    :start => [$2,$3].sort.first,
    :stop => [$2,$3].sort.last,
    :hmm => $4,
    :nncleavagesite => $5 
  }

end

def get_coords_tab line
  line = line.split(/\s+/)
  #ID     algorithm       score   start   stop    sequence
  line[0] =~ /(Cf746836_TGAC_s1v1_scaffold_\d+)_/;
  {
    :contig => $1,
    :sequence => line[-1],
    :id => line[0],
    :start => line[3].to_i,
    :stop => line[4].to_i,
    :score => line[2].to_f,
    
  }
end

 #Bio::FastaFormat.open(ARGV[0]).collect {|z| get_coords z }
 
 puts File.open(ARGV[0]).readlines.collect {|z| get_coords_tab z }.to_json
