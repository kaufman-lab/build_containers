library(eacSTpredict)
library(data.table)

args <- commandArgs(trailingOnly=TRUE)
if(length(args) != 2){
    stop("Provide covariate file and pollutant as command arguments") 
}
cov <- fread(args[1])
pred <- predictST_national(cov, args[2])
fwrite(pred) # write to stdout
