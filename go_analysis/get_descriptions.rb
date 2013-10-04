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
require 'net/http'

#def write_gaf
  
#end

data = Hash.new {|h,k| h[k] = {} }
all_terms = []

File.open(ARGV[0]).each do |line|
  next unless line =~ /\w+/
  result = JSON.parse(line.chomp.chop)
  gene = result.keys.first
  result[gene].each do |goterm|
    begin
      next unless goterm.length > 3
      s = Net::HTTP.get('www.ebi.ac.uk', "/QuickGO/GAnnotation?format=tsv&goid=#{goterm}&col=goName&limit=1&termUse=slim")
      desc = s.chomp.split("\n").last
      all_terms << goterm
      #puts ["UniProtKB",gene,gene,goterm,'PMID:12345','IEA','F','protein','57401','20090118','DM1'].join("\t")
      data[gene][goterm] = desc
    rescue
      $stderr.puts "meh..."
    end
  end
end

File.open("terms_and_descriptions.json", "w").write(data.to_json)
#File.open("list_of_terms.txt", "w").write( all_terms.join("\n") )

#write_gaf all_terms