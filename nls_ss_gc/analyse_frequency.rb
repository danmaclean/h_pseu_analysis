#!/usr/bin/ruby
# encoding: utf-8
#
#  untitled.rb
#
#  Created by Dan MacLean (TSL) on 2013-10-01.
#  Copyright (c). All rights reserved.
#
require 'pp'
require 'json'
require 'csv'
require 'bio'
require 'barmcakes'

args = Arrghs.parse_and_check(
      '--fasta' => 'a fasta file of the genome',
      '--nls' => 'json file of nuclear signal predictions',
      '--ss' => 'json file of secretion peptide predictions'
      )


nls_all = JSON.parse(File.open(args[:nls]).read)
ss_all = JSON.parse(File.open(args[:ss]).read)
seqs = Bio::FastaFormat.open(args[:fasta]).collect {|x| x}

puts ['scaffold','start','stop','nls_count','ss_count','gc_percent'].join("\t")
windows = Hash.new {|h,k| h[k] = [] }
Bio::DB::FastaLengthDB.new(args[:fasta]).each do |seqid, length|
  nls = nls_all.select {|n| n['contig'] == seqid}

  ss = ss_all.select {|n| n['contig'] == seqid}
  seq = Bio::Sequence::NA.new( seqs.select {|s| s.entry_id == seqid }.first.seq )
  
  step = 10000
  (1..length).step(step) do |window|
    stop = window + step
    stop = length if length - window < step
    nls_count = nls.select {|n| n['start'] > window and n['stop'] < stop + n['sequence'].length }.length
    ss_count = ss.select {|n| n['start'].to_i > window  and n['stop'].to_i < stop + n['sequence'].length }.length
    gc_percent = seq.subseq(window, stop).gc_percent
    puts [seqid, window,stop, nls_count, ss_count, gc_percent].join("\t")
    windows[seqid] << [stop, nls_count, ss_count]
  end
  
end