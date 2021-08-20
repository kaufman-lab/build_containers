#!/usr/bin/Rscript

images <- list.files("./build_scripts")

lapply(images, function(i){
  bootstrap_exists <- file.exists(file.path("build_scripts",i,"bootstrap"))
  dependencies_exists <- file.exists(file.path("build_scripts",i,"dependencies.R"))
  stopifnot(bootstrap_exists || dependencies_exists) #the image must depend on another image OR have a bootstrap
  if(bootstrap_exists && dependencies_exists){
    stop("bootstrap file and dependency file cannot both be specified.")
  }
  
  if(dependencies_exists){
    source(file.path("build_scripts",i,"dependencies.R"))
    if(!exists("dependencies")){
      stop("dependencies file detected but sourcing this R file does not result in creation of global object named dependencies")
    }
  }else{
    dependencies <- NULL
  }
  
  if(length(unique(dependencies)) !=length(dependencies)){
    stop("duplicated dependencies detected")
  }
  
  dependencies <- c(dependencies,  i)
  
  if(length(unique(dependencies)) !=length(dependencies)){
    stop("current image detected in dependencies vector. Please remove this.")
  }
  
  #bootstrap is a special case. there must only be one
  outfile <- paste0(i, ".def")
  f <- file(outfile, open="w") #open a connection to the definition file for writing
  
  if(bootstrap_exists){
    bootstrap <- readLines(file.path("build_scripts",i,"bootstrap"))
  }else{
    parent_bootstrap_filepath <- file.path("build_scripts",dependencies[[1]],"bootstrap")
    bootstrap <- readLines(parent_bootstrap_filepath)
  }
  writeLines(bootstrap, con = f)
  
  #every other section can have multiple scripts concataned together. 
   #Note this is why it's important to specify dependencies in order--scripts from earlier dependencies are run before later
    #current image sections are run last
  
  definition_sections <- c("%setup","%files","%post","%environment")
  
  lapply(definition_sections,function(s){
    separator <- "#######################################"
    writeLines(c("\n", separator, s, separator, "\n"), con = f)
    
    lapply(dependencies,function(d){
      current_file <- file.path("build_scripts",d,s)
      if(file.exists(current_file)){
        writeLines(readLines(current_file), con = f)
        writeLines("\n", con = f)
      }
        #skip silently if file doesn't exist
    })
  })
  
  close(f)

  
})
