#$1 tophat outdir
#$2 left reads
#$3 right reads

source bowtie2-2.1.0
source tophat-2.0.8b
source boost-1.53.0
tophat -o $1 -r 200 --b2-very-sensitive -G Chalara_fraxinea_ass_s1v1_ann_v1.1.gene.gff scafflolds $2 $3