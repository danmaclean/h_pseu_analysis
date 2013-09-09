make_dataframe <- function(filename, insert_size_identifier){
    
    df <- read.csv(filename, sep=" ", 
                   header=FALSE, 
                   col.names=c("chr","start","stop","average_insert_size"), 
                   colClasses=c('character', 'numeric', 'numeric', 'numeric')
    );
    
    df <- mutate(df, insert_type=as.factor(insert_size_identifier));
    
}

setup_environment <- function(){
	rm(list=ls())
	library(plyr)
	library(ggplot2)
}