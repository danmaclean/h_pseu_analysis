#!/usr/bin/ruby
# encoding: utf-8
#
#  untitled.rb
#
#  Created by Dan MacLean (TSL) on 2013-07-08.
#  Copyright (c). All rights reserved.
#
require 'pp'
require 'yaml'
##run a SNP calling using GATK with 

class ConfigFile
  require 'yaml'
  def self.write(file="gatk_config.yml", opts={})
    opts = {
    "GATK" => "", #absolute location of GATK
    "PICARD_DIR" => "", #absolute location of Picard
    "SAMTOOLS" => "", #absolute location of samtools
    "BAM" => "", # name of BAM file to start with (unsorted, no read group information)
    "RGID" => "", # read group ID
    "RGLB" => "", # read group library name
    "RGPL" => "", #read group platform
    "RGPU" => "", #read group platform unit e.g barcode id
    "RGSM" => "",  #sample name
    "FASTA" => "", #reference_file
    "SNP_FILTER" => "QD < 2.0 || FS > 60.0 || MQ < 40.0 || HaplotypeScore > 13.0 || MappingQualityRankSum < -12.5 || ReadPosRankSum < -8.0",
    "INDEL_FILTER" => "QD < 2.0 || FS > 200.0 || ReadPosRankSum < -20.0"
    }.merge! opts
  
    f = File.open(file,"w")
    f.puts(opts.to_yaml)
    f.close
    return file
    
  end
  
end



class GATKRunner
  
require 'yaml'
  
def initialize(yaml)
  opts = YAML.load_file(yaml)
  opts.each_pair do |k,v|
    self.instance_variable_set("@" + k.to_s,v)
  end
  @bash = []
  @make_bash = false
end

def execute(cmd="")
  if @make_bash
    @bash << cmd
  else
    begin
      system cmd
    rescue Exception => e
      $stderr.puts e
      exit
    end
  end
end

def add_read_groups(input="accepted_hits.bam", output="sorted_accepted_hits_plus_read_groups.bam")
  cmd = "java -jar #{@PICARD_DIR}/AddOrReplaceReadGroups.jar INPUT=#{input} OUTPUT=#{output} SORT_ORDER=coordinate RGID=#{@RGID} RGLB=#{@RGLB} RGPL=#{@RGPL} RGPU=#{@RGPL} RGSM=#{@RGSM}"
  execute cmd
  output
end

def mark_and_remove_dups(input="sorted_accepted_hits_plus_read_groups.bam", output="mark_dup_sorted.bam")
  cmd = "java -jar #{@PICARD_DIR}/MarkDuplicates.jar INPUT=#{input} OUTPUT=#{output} REMOVE_DUPLICATES=true  METRICS_FILE=metrics.txt"
  execute cmd
  output
end

def remove_secondary_alignments(input="mark_dup_sorted.bam", output="mark_dup_sorted_primary.bam")
  cmd = "#{@SAMTOOLS} view -bF 0x100 #{input} > #{output}"
  execute cmd
  output
end

def index_bam(input="mark_dup_sorted.bam",output="")
  cmd = "java -jar #{@PICARD_DIR}/BuildBamIndex.jar INPUT=#{input}"
  execute cmd
  output
end

def make_sequence_dict(input="reference.fa",output="ref.dict")
  output = input.gsub(/fa$/,"dict")
  return output  if File.exists?(output)
  cmd = "java -jar #{@PICARD_DIR}/CreateSequenceDictionary.jar REFERENCE=#{input} OUTPUT=#{output}"
  execute cmd
  output
end

def reorder_header(input="mark_dup_sorted.bam", output="mark_dup_reordered.bam", reference="reference.fa")
  cmd = "java -jar #{@PICARD_DIR}/ReorderSam.jar INPUT=#{input} OUTPUT=#{output} REFERENCE=#{reference}"
  execute cmd
  output
end

def local_realign(input="reordered.bam", reference="reference.fa", output="realigned.bam")
  cmd = "java -jar #{@GATK} \
  -T RealignerTargetCreator \
  -R #{reference} \
  -I #{input} \
  -o target_intervals.list"
  execute cmd
  
  cmd = "java -jar #{@GATK} \
  -T IndelRealigner \
  -R #{reference} \
  -I #{input} \
  -targetIntervals target_intervals.list \
  -o #{output}"
  execute cmd
  output
end

def run_unified_genotyper(input="realigned.bam",reference="reference.fa", output="raw_calls.vcf")
  cmd = "java -jar #{@GATK} \
  -T UnifiedGenotyper \
  -R #{reference} \
  -I #{input} \
  -glm BOTH \
  -stand_call_conf 30 \
  -stand_emit_conf 10 \
  -o #{output}"
  execute cmd
  output
end

def extract_variants(input="raw_calls.vcf", reference="reference.fa", output="raw_variants.vcf",type="SNP")
  cmd = "java -jar #{@GATK} \
  -T SelectVariants \
  -R #{reference} \
  -V #{input} \
  -selectType #{type} \
  -o #{output}" 
  execute cmd
  output
end

def filter_variants(input="raw_variants.vcf",reference="reference.fa",output="filtered_variants.vcf", type="SNP")
  expression = case type
  when "SNP"
    @SNP_FILTER
  when "INDEL"
    @INDEL_FILTER
  end
  
  cmd = "java -jar #{@GATK} \
  -T VariantFiltration \
  -R #{reference} \
  -V raw_snps.vcf \
  --filterExpression \"#{expression}\" \
  --filterName \"my_snp_filter\" \
   -o #{output}"
  execute cmd
  
end

def clean_up file
  cmd = "rm #{file}"
  execute cmd
end


def run(opts = {:make_bash_script => false} )
  @make_bash = opts[:make_bash_script]
  sorted_plus_rg = add_read_groups @BAM

  marked_dup = mark_and_remove_dups sorted_plus_rg
  index_bam marked_dup 
  clean_up sorted_plus_rg

  make_sequence_dict @FASTA 
  
  reordered_bam = reorder_header(marked_dup, "mark_dup_reordered.bam", @FASTA)
  index_bam reordered_bam
  clean_up marked_dup

  primary_alignments = remove_secondary_alignments(reordered_bam, "mark_dup_reordered_primary.bam")
  clean_up reordered_bam
  index_bam primary_alignments

  realigned_bam = local_realign(input=primary_alignments,reference=@FASTA,output="realigned.bam")
  clean_up primary_alignments

  raw_variants = run_unified_genotyper(realigned_bam,@FASTA,"raw_calls.vcf")
  raw_snp_file = extract_variants(raw_variants,@FASTA,"raw_snps.vcf","SNP")
  raw_indel_file = extract_variants(raw_variants,@FASTA,"raw_indels.vcf","INDEL")
  
  filter_variants(raw_snp_file,@FASTA,"filtered_snps.vcf","SNP")
  filter_variants(raw_indel_file,@FASTA,"filtered_indels.vcf","INDEL")
  
  if @make_bash
    f = File.open("run_gatk.sh","w")
    f.write @bash.join(" &&\n")
    f.close
  end
end

end

#file = ConfigFile.write
GATKRunner.new("gatk_config.yml").run(:make_bash_script => true)
