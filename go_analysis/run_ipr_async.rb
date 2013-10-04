#!/usr/bin/ruby
# encoding: utf-8
#
#  untitled.rb
#
#  Created by Dan MacLean (TSL) on 2013-09-27.
#  Copyright (c). All rights reserved.
#
require 'pp'
require 'json'
require 'csv'
require 'bio'
require 'barmcakes'
require 'fileutils'

def get_go_annotations_from_svg(file_list)
  annos = {}
  file_list.each do |svg|
    #puts svg
    svg_string = File.open(svg, "r").read
    #puts svg_string
    svg_string =~ /<title>(.*)?<\/title>/
    title = $1
    gos = svg_string.scan /xlink:href="http:\/\/www.ebi.ac.uk\/QuickGO\/GTerm\?id=(GO:\d+)"/
    annos[title] = gos.flatten
  end
  annos
end

def read_submitted
  lines = File.open("submitted.log", "r").read
  lines.split("\n") 
end

def write_submitted job
  File.open("submitted.log", "a+").write("#{job}\n")
end

def submit_bundles
  Bio::FastaFormat.open(ARGV[0]).each_slice(25).each_with_index do |seqs, batch|
    
    string = seqs.collect {|s| s.to_s}.join("")
    job = `echo '#{string}' | perl ../iprscan5_lwp.pl --email dan.maclean@tsl.ac.uk --async --goterms --multifasta -`
    puts job
    write_submitted job
  end
end

def read_done
  lines = File.open("done.log", "r").read
  lines.split("\n")
end

def write_done job
  File.open("done.log", "a+").write("#{job}\n")
end

def check_if_done
    submitted = read_submitted
    done = read_done

    submitted.each do |job|
      next unless job =~ /\w/
      next if done.include? job
      if `perl iprscan5_lwp.pl --status --jobid #{job}` =~ /FINISHED/
        get_result_for job
      end
    end 
    
end

def get_result_for job
  FileUtils.mkdir("#{job}")
  FileUtils.cd("#{job}")
  system("perl ../iprscan5_lwp.pl --polljob --jobid #{job}")
  annos = get_go_annotations_from_svg Dir.glob("*.svg")
  File.open("../results.json", "a+").write("#{annos.to_json},\n")
  FileUtils.cd("../")
  FileUtils.rm_rf("#{job}")
  File.open("done.log", "a").write("#{job}\n")
end



if ARGV[1] == 'submit'
  submit_bundles
elsif ARGV[1] == 'get_results'
  check_if_done
end