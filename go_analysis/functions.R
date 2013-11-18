setup_environment <- function(){
  rm(list = ls())
  library('RJSONIO')
  library('ggplot2')
  library('plyr')
  
}

data_frame_from_json_file <- function(json_file){
  json <- fromJSON( json_file )
  df <- data.frame(description=factor(), gene=factor(), term=factor() )
  for (i in 1:length(json)){
    d <- as.data.frame(json[i])
    e <- mutate(d, gene = names(d))
    f <- mutate(e, term = as.factor(row.names(e)))
    f <- mutate(f, count=1)
    colnames(f) <- c("description","gene","term", "count")
    f$term <-as.factor(f$term)
    f$description <- as.factor(f$description)
    df <- rbind(f, df)
  }
  ##add in the GO namespace column
  a <- fromJSON("term_mapping.json")
  b <- as.data.frame(a)
  b <- t(b)
  b <- as.data.frame(b)
  colnames(b) <- c("term","namespace")
  df <- merge(df, b, by.x = 'term', by.y = 'term')
  ##this df now has a messed up names attribute I can't fix.
  ## ditch it by dumping to disc and loading it back in
  ##
  write.csv(df, "x.csv")
  df <- read.csv("x.csv")
  
  return(df)
}