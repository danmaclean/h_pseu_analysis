#!/usr/bin/ruby
# encoding: utf-8
#
#  untitled.rb
#
#  Created by Dan MacLean (TSL) on 2013-11-18.
#  Copyright (c). All rights reserved.
#

require 'bio'
require 'barmcakes'
require 'pp'

args = Arrghs.parse_and_check(
  "--fasta" => "a fasta file" 
  )

@genome_size = 63000000.0  
@seq_lengths = Bio::FastaFormat.open(args[:fasta])
  .collect {|x| x }
  .sort {|a,b| b.length <=> a.length}
  .collect {|s| s.length }

def calc_x50 boundary
  sum = 0.0
  @seq_lengths.each_with_index do |obj, idx|
    sum = obj + sum
    return @seq_lengths[idx] if sum >= boundary
  end
  return 0
end


(1..100).step(1) do |x|
  boundary = x  * ( @genome_size / 100 )
  current = calc_x50 boundary
  puts [x, current].join(",")
end

