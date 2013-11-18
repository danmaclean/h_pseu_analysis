# Identifying wood decay related proteins in Chalara TGAC Assembly 1.1

The list of CAZY wood decaying proteins in [Floudas] [] was used as input to BLAST searches to identify proteins with strong sequence identity in the Chalara [protein list] [], with the following protocol:

```ruby
#!/usr/bin/ruby
# encoding: utf-8
#
#  untitled.rb
#
#  Created by Dan MacLean (TSL) on 2013-07-30.
#  Copyright (c). All rights reserved.
#
require 'pp'
require 'json'
require 'csv'
require 'bio'
require 'barmcakes'


require 'find'

def format_db(file, type=prot)
  system("makeblastdb -dbtype #{type} -in #{file}")
end

def find_files(start_dir, reg_exp)
  Find.find(start_dir).select { |x| x =~ reg_exp}
end


def blast(input_file, database, program, pcmin,emin)
  results = []
        blast_file= `#{program} -db #{database} -query #{input_file} -outfmt '10 qseqid qacc sseqid sacc pident evalue ' > tmp`
        File.open("tmp", "r").each_line do |line|
          blast_r = line.gsub(/\n/,",").split(",")[0..5]
          if blast_r[-1].to_f <= emin.to_f and blast_r[-2].to_f > pcmin and not blast_r[0] == blast_r[2]
            puts "#{blast_r}"
            results << blast_r[0]
          end
        end
        #$stderr.puts results
  return results.uniq.compact
end

def get_within_group_blast_limits(file,program="blastp" )
  blast_file= `#{program} -db #{file} -query #{file} -num_alignments 2 -outfmt '10 qseqid qacc sseqid sacc pident evalue ' > within`
  pcs = []
  es = []
  File.open("within", "r").each_line do |line|
    arr = line.split(/,/)
    next if arr[0] == arr[2]
    pcs << arr[-2].to_f
    es << arr[-1].chomp.to_f
  end
  #get value at 50 pc
  pcs_50 =  pcs.sort.reverse[(pcs.size / 2.0).floor]
  es_50 = es.sort.reverse[(es.size / 2.0).floor]
  $stderr.puts "#{pcs.sort.reverse} = #{pcs_50} and #{es.sort.reverse} = #{es_50}"
  [pcs_50,es_50]
end

def count_proteins_per_org(file)
    counts = Hash.new {|h,k| h[k] = 0 }
    Bio::FastaFormat.open(file).each do |entry|
      org = entry.entry_id.split(/_/)[0].gsub(/\d/,"")
      counts[org] = counts[org] + 1
    end
    counts
end

def clean_up
  system("rm *.p*")
  system("rm tmp")
end


args = Arrghs.parse_and_check("--fasta"=> "a fasta file of genes to search",
                              "--start_dir" => "directory to loop through")


##take each chalara protein blast it against each set of protein group files in turn

all_fams = []
all_orgs = ["Chalara"]
result = Hash.new {|h,k| h[k] = Hash.new }
files = Dir.glob("./*")
files.each do |file|
  next if file == '.' or file == '..'
  next if File.directory?(file)
  next if file =~ /DS_Store/
  next if file =~ /heatmap/
  next if file =~ /match/
  $stderr.puts "Doing #{file}..."
  all_fams << file
  format_db(file, "prot")
  pcmin,emin = get_within_group_blast_limits(file)
  blast_results = blast(args[:fasta],file,"blastp",pcmin,emin)
  result[file]["Chalara"] = blast_results.length
  counts = count_proteins_per_org(file)
  counts.each_pair do |org,c|
    result[file][org] = c
  end
  all_orgs = all_orgs + counts.keys
  clean_up
end
#$stderr.puts result
out = File.open("heatmap.txt", "w")
out.puts [" ", all_orgs.uniq].uniq.compact.join("\t")
all_fams.uniq.each do |fam|
  arr = [fam.gsub(/\.\//,"")]
  all_orgs.uniq.each do |org|
    if result[fam].has_key?(org)
      arr << result[fam][org]
    else
      arr << 0
    end
  end
  out.puts arr.join("\t")
end
out.close
```
A heatmap image was generated from the output file `heatmap.txt` with [MeV] [].



## References

[Floudas]: http://dx.doi.org/10.1126/science.1221748 "Floudas"
[protein list]: http://github.com/ash_dieback/chalara_fraxinea/Kenninghall_wood_KW1/annotations/Gene_predictions/TGAC_Chalara_fraxinea_ass_s1v1_ann_v1.1/Chalara_fraxinea_ass_s1v1_ann_v1.1.protein.faa 
[MeV]: www.tm4.org/mev.html
