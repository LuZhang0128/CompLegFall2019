#####################
# load libraries
# clear global .envir
#####################
# remove objects
rm(list=ls())
# detach all libraries
detachAllPackages <- function() {
  basic.packages <- c("package:stats","package:graphics","package:grDevices","package:utils","package:datasets","package:methods","package:base")
  package.list <- search()[ifelse(unlist(gregexpr("package:",search()))==1,TRUE,FALSE)]
  package.list <- setdiff(package.list,basic.packages)
  if (length(package.list)>0)  for (package in package.list) detach(package, character.only=TRUE)
}
detachAllPackages()

# load libraries
pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg)) 
    install.packages(new.pkg, dependencies = TRUE)
  sapply(pkg, require, character.only = TRUE)
}

lapply(c("stringr", "dplyr", "plyr", "tidyverse", "rvest", "zoo", "lubridate"), pkgTest)

#######################
# working directoy
#######################
setwd("~/Documents/GitHub/CompLegFall2019/data/uk_lower")

########################
# download all csv files
########################
# create function that takes inputs of:
# (1) type: what data base do you want to access (bills, divisions, etc.)?
# (2) maxPages: this is the number of web pages the documents are stored across
# the API only lets you download 500 at a time, so you have to iterate over pages
# (3) fileName: where is the destination of the file? 
# Our labelling is slightly different than the website (ex: "answeredquestions" & "Written_Responses")
download_csv <- function(type, maxPages, fileName){
  for(i in 0:maxPages) {
    # make URL
    
    url <- str_c("http://lda.data.parliament.uk/", type,".csv?_pageSize=500&_page=", i, collapse = "")
    url
    # make file name
    file <- str_c(getwd(), "/", fileName, "/", type, "_page_", i, ".csv", collapse = "")
    # download file
    tryCatch(download.file(url, file, quiet = TRUE), error = function(e) print(paste(file, 'questions missing')))
    
    # random delay
    Sys.sleep(runif(1, 0, 0.15))
  }
}

download_csv("commonswrittenquestions", 510, "Written_Questions") 





