cd ~/facebook/ashwellthorpe_AT1/tophat &&
cp ~/Desktop/run_gatk.rb . && ruby run_gatk.rb && bsub -o job.log -e job.err "sh run_gatk.sh" && 

cd ~/facebook/ashwellthorpe_AT2/tophat &&
cp ~/Desktop/run_gatk.rb . && ruby run_gatk.rb && bsub -o job.log -e job.err "sh run_gatk.sh" &&

cd ~/facebook/upton_broad_and_marshes_UB1/tophat &&
cp ~/Desktop/run_gatk.rb . && ruby run_gatk.rb && bsub -o job.log -e job.err "sh run_gatk.sh" &&

cd ~/facebook/kenninghall_wood_KW1/tophat &&
cp ~/Desktop/run_gatk.rb . && ruby run_gatk.rb && bsub -o job.log -e job.err "sh run_gatk.sh"
