#!/usr/bin/ruby
# encoding: utf-8
#
#  untitled.rb
#
#  Created by Dan MacLean (TSL) on 2013-10-04.
#  Copyright (c). All rights reserved.
#

require 'bio'
require 'pp'

genes = Bio::GFF::GFF3.new(File.read('bgh_dh14_v3_0_annotations_gff')).records.select {|x| x.feature == 'gene'}

result = genes.collect{|x| x.attributes.select{ |y| y.first == 'Ontology_term'} }

total = 0
hash = Hash.new {|h,k| h[k] = 1}
result.each do |t,r|
  next if [t,r].include? nil
  term = r.last
  hash[term] = hash[term] + 1
  total = total + 1
end

hash.each_pair do |h,k|

  puts [ h.gsub(/"/,""),k,total].join("\t")
end
