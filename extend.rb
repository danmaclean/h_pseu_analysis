#!/usr/bin/ruby
# encoding: utf-8
#
#  untitled.rb
#
#  Created by Dan MacLean (TSL) on 2013-06-26.
#  Copyright (c). All rights reserved.
#
require 'pp'
require 'json'
require 'csv'
require 'bio'
require 'barmcakes'
require 'bio-samtools'

class Bio::GFF::GFF3::Record
  
  def gff_id
    self.attributes.select {|x| x.first == "ID"}.first.last
  end
  
end


 class File
  
  def self.get_genes_from_gff_by_chromosome file
    genes = Hash.new {|h,k| h[k] = [] }
    File.open(file).each_except_comments do |line|
      gff = Bio::GFF::GFF3::Record.new(line)
      genes[gff.seqname] << gff if gff.feature == 'gene'
    end
    genes
  end
  
  def self.get_genes_keyed_by_id file
    genes = Hash.new {|h,k| h[k] = {} }
    File.open(file).each_except_comments do |line|
      gff = Bio::GFF::GFF3::Record.new(line)
      if gff.feature == 'gene'
        genes[gff.gff_id][:gff] = gff 
      end
    end
    genes
  end
 
 end
  
  
  def within(limit, a,b)
    if  ( (a.start - b.start).abs <= limit) or  ( (a.end - b.start).abs <= limit) or  ( (a.end - b.end).abs <= limit) or  ( (a.start - b.end).abs <= limit)
      return true
    end
    false
  end
  
  def keep_genes_within_100_on_different_strands genes
    result = Hash.new {|h,k| h[k] = [] }
    genes.each_pair do |chr,list|
    list.each do |a|
      list.each do |b|
        next if a == b
          if a.strand != b.strand and within(200,a,b)
            result[chr] << [a,b].sort_by {|x| [x.start, x.strand] }.map {|c| c.to_s }
          end
      end
    end
    result[chr].uniq!
    end
    result
  end
  
  def convert bool
    bool ? "+" : "-"
  end

  def extend_with_reads(gff,direction)
    bam = Bio::DB::Sam.new(:bam => @args[:bam], :fasta => @args[:ref])
    bam.open
    extent = case direction
    when :three_prime
        reads = []
        begin
          limit = gff.end + 1000
          bam.fetch(gff.seqname,gff.end,limit ).each do |aln|
            reads << aln
          end
        rescue Exception => e
          
        end
        
        last = gff.end.to_i
        reads.sort_by {|x| x.pos }.each do |read|
          if read.pos.to_i <= last.to_i and gff.strand == convert(read.query_strand)
            
            last = read.calend
          end
        end
        last
    when :five_prime
        reads = []
        begin
          limit = gff.start - 1000
          limit = 1 if limit < 1
          bam.fetch(gff.seqname,(limit),gff.start ).each do |aln|
            reads << aln
          end
        rescue Exception => e
          
        end
        last = gff.start.to_i
        reads.sort_by {|x| x.pos }.reverse.each do |read|
          if read.calend.to_i >= last.to_i and gff.strand == convert(read.query_strand)
            last = read.pos
          end
        end
        last
    end
    bam.close
    return extent
  end
  
  
  
  ###################################################################
  
  @args = Arrghs.parse_and_check("--gff" => "a gff file", 
                               "--bam" => " a sorted bam file"
                               )
  
  genes = File.get_genes_from_gff_by_chromosome @args[:gff]
  gene_table = File.get_genes_keyed_by_id(@args[:gff])
  $stderr.puts "got gene_table"
  final_genes = {}
  
  
  genes = keep_genes_within_100_on_different_strands genes
  
  genes.each_pair do |chr,list|
    list.each do |pair|
        left = Bio::GFF::GFF3::Record.new(pair.first)
        right = Bio::GFF::GFF3::Record.new(pair.last)
        begin
          left_extent = extend_with_reads(left,:three_prime)
          #left_hist.puts "#{left_extent - left.end}"
          #puts "gff was #{left.to_s} \t now is #{left_extent}"
          $stderr.puts "left extended by #{left_extent - left.end} : end was #{left.end}, is #{left_extent}"
          right_extent = extend_with_reads(right, :five_prime)
          $stderr.puts "right extended by #{right.start - right_extent} : start was #{right.start}, is #{right_extent}"
          #puts "gff was #{right.to_s} \t now is #{right_extent}"
          
          gene_table[left.gff_id][:end] =  left_extent
          gene_table[right.gff_id][:start] = right_extent
          
        rescue
        end
    end
  end

  gene_table.each_key do |gff_id|
      $stderr.puts gff_id
      next unless gene_table[gff_id].has_key?(:start) or gene_table[gff_id].has_key?(:end)
      edit = []
      start = gene_table[gff_id][:gff].start
      if gene_table[gff_id].has_key?(:start)
        start = gene_table[gff_id][:start] 
        edit << "start" 
      end
      stop = gene_table[gff_id][:gff].end 
      if gene_table[gff_id].has_key?(:end)
        stop = gene_table[gff_id][:end]
        edit << "end"
      end
      gff = gene_table[gff_id][:gff]
      attributes = []
      gff.attributes.each do |arr|
        attributes << arr.join("=")
      end
      attribs = attributes.join(";")
      puts [gff.seqid, gff.source, gff.feature, start, stop, ".", gff.strand, ".", attribs].join("\t")
  end
