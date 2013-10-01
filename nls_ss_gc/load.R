setup_environment()

  data <- read.table('nls_ss_gc.csv', sep="\t", 
                   header=TRUE, 
                   col.names=c('scaffold', 'start', 'stop', 'nls_count', 'ss_count', 'gc_percent'), 
                   colClasses=c('factor', 'numeric', 'numeric', 'numeric', 'numeric', 'numeric') )

