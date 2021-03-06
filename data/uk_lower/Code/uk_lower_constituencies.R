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
    # make file name
    file <- str_c(getwd(), "/", fileName, "/", type, "_page_", i, ".csv", collapse = "")
    # download file
    # tryCatch(download.file(url, file, quiet = TRUE), error = function(e) print(paste(file, 'questions missing')))
    
    # random delay
    Sys.sleep(runif(1, 0, 0.15))
  }
}

download_csv("constituencies", 7, "Constituencies")

############################
# read the download csv
# bind them together
############################
do.call_rbind_read.csv <- function(path, pattern = "*.csv") {
  files = list.files(path, pattern, full.names = TRUE)
  do.call(rbind, lapply(files, function(x) read.csv(x, stringsAsFactors = FALSE, na.strings="")))
}

df <- do.call_rbind_read.csv('~/Documents/GitHub/CompLegFall2019/data/uk_lower/Constituencies')

###########################
# parse the dataset
###########################
df<- df %>%
  mutate(start_term = as.factor(started.date)) %>%
  mutate(end_term = as.factor(ended.date))

# changing the dates to parliament numbers
oridate <- levels(df$start_term)
oridate[oridate>="2017-06-08"] = 57
oridate[oridate<"2017-06-08" & oridate >= "2015-05-07"] = 56
oridate[oridate>="2010-05-06" & oridate < "2015-05-07"] = 55
oridate[oridate<"2010-05-06" & oridate >= "2005-05-05"] = 54
oridate[oridate>="2001-06-07" & oridate < "2005-05-05"] = 53
oridate[oridate<"2001-06-07" & oridate >= "1997-05-01"] = 52
oridate[oridate>="1992-04-09" & oridate < "1997-05-01"] = 51
oridate[oridate<"1992-04-09" & oridate >= "1987-06-11"] = 50
oridate[oridate>="1983-06-09" & oridate < "1987-06-11"] = 49
oridate[oridate<"1983-06-09" & oridate >= "1979-05-03"] = 48
oridate[oridate>="1974-10-10" & oridate < "1979-05-03"] = 47
oridate[oridate<"1974-10-10" & oridate >= "1974-02-28"] = 46
oridate[oridate>="1970-06-18" & oridate < "1974-02-28"] = 45
oridate[oridate<"1970-06-18" & oridate >= "1966-03-31"] = 44
oridate[oridate>="1964-10-15" & oridate < "1966-03-31"] = 43
oridate[oridate<"1964-10-15" & oridate >= "1959-10-08"] = 42
oridate[oridate>="1955-05-26" & oridate < "1959-10-08"] = 41
oridate[oridate<"1955-05-26" & oridate >= "1951-10-25"] = 40
oridate[oridate>="1950-02-23" & oridate < "1951-10-25"] = 39
oridate[oridate<"1950-02-23" & oridate >= "1945-07-05"] = 38
oridate[oridate>="1935-11-14" & oridate < "1945-07-05"] = 37
oridate[oridate=="1918-12-14"] = 31
oridate[oridate=="1900-01-01"] = 26
levels(df$start_term) <- oridate

oridate <- levels(df$end_term)
oridate[oridate>="2017-06-08"] = 57
oridate[oridate<"2017-06-08" & oridate >= "2015-05-07"] = 56
oridate[oridate>="2010-05-06" & oridate < "2015-05-07"] = 55
oridate[oridate<"2010-05-06" & oridate >= "2005-05-05"] = 54
oridate[oridate>="2001-06-07" & oridate < "2005-05-05"] = 53
oridate[oridate<"2001-06-07" & oridate >= "1997-05-01"] = 52
oridate[oridate>="1992-04-09" & oridate < "1997-05-01"] = 51
oridate[oridate<"1992-04-09" & oridate >= "1987-06-11"] = 50
oridate[oridate>="1983-06-09" & oridate < "1987-06-11"] = 49
oridate[oridate<"1983-06-09" & oridate >= "1979-05-03"] = 48
oridate[oridate>="1974-10-10" & oridate < "1979-05-03"] = 47
oridate[oridate<"1974-10-10" & oridate >= "1974-02-28"] = 46
oridate[oridate>="1970-06-18" & oridate < "1974-02-28"] = 45
oridate[oridate<"1970-06-18" & oridate >= "1966-03-31"] = 44
oridate[oridate>="1964-10-15" & oridate < "1966-03-31"] = 43
oridate[oridate<"1964-10-15" & oridate >= "1959-10-08"] = 42
oridate[oridate>="1955-05-26" & oridate < "1959-10-08"] = 41
oridate[oridate<"1955-05-26" & oridate >= "1951-10-25"] = 40
oridate[oridate<"1955-05-26" & oridate >= "1951-10-25"] = 39
oridate[oridate<"1955-05-26" & oridate >= "1951-10-25"] = 38
oridate[oridate<"1955-05-26" & oridate >= "1951-10-25"] = 37
oridate[oridate<"1955-05-26" & oridate >= "1951-10-25"] = 36
oridate[oridate<"1955-05-26" & oridate >= "1951-10-25"] = 35
oridate[oridate<"1955-05-26" & oridate >= "1951-10-25"] = 34
oridate[oridate>="1950-02-23" & oridate < "1951-10-25"] = 39
oridate[oridate<"1950-02-23" & oridate >= "1945-07-05"] = 38
oridate[oridate>="1935-11-14" & oridate < "1945-07-05"] = 37
levels(df$end_term) <- oridate

# change factors to numerics and take out NA's
sett <- df %>%
  mutate(start = as.numeric(as.character(start_term))) %>%
  mutate(end = as.numeric(as.character(end_term)))
sett$end[is.na(sett$end)]=57
sett1 <- sett %>%
  mutate(freq = end-start+1)

# expand the data frame to one entry for each parliament
df_a <- sett1 %>%
  uncount(weights = freq, .id = "n", .remove = F) %>%
  mutate(parliament_number = start+n-1) %>%
  select(label, parliament_number) %>%
  unique()

# # find the country for each contituency
# df$country_name <- substr(df$gss.code,1,1)
# df$country_name[df$country=="W"] <- "Wales"
# df$country_name[df$country=="E"] <- "England"
# df$country_name[df$country=="S"] <- "Scotland"
# df$country_name[df$country=="N"] <- "Northern Ireland"
# 
# # select label and country
# # change label to constituency name, replace & by and
# # keep unique terms
# df$constituency_name <- gsub("&", "and", df$label)
# df_a <- df %>%
#   select(constituency_name) %>%
#   distinct()
# df_b <- df %>%
#   select(constituency_name,country_name) %>%
#   distinct() %>%
#   na.omit()
# df_c <- merge(df_a, df_b, by="constituency_name",all.x = T)

# One Member of Parliament (MP) in the House of Commons represents a single constituency.
df_a$chamber_number <- 1
df_a$chamber_name <- "House of Commons"
df_a$constituency_name <- gsub("&", "and", df_a$label)

# A number assigned to each chamber. Assigned with constituencies sorted by name.
df_b <- df_a %>%
  select(constituency_name) %>%
  distinct()
df_b$constituency_number <- rownames(df_b)

# merge it back to df_a
df_d <- merge(df_a, df_b, by="constituency_name", all.x=T)

# observation number is based on chamber number and constituency number
df_e <- df_d[order(as.numeric(df_d$chamber_number), as.numeric(df_d$constituency_number)), ]
rownames(df_e) <- c()
df_e$observation_number <- rownames(df_e)

# set pathes
df_e$chamber_path <- paste("/chamber-",df_e$chamber_number,sep="") 
df_e$constituency_path <- paste(df_e$chamber_path,"/constituency-",df_e$constituency_number,sep="") 
df_e$observation_path <- paste(df_e$chamber_path,"/constituency-",df_e$observation_number,sep="") 
df_e$parliament_path <- paste(df_e$chamber_path,"/constituency-",df_e$constituency_number, "/parliament-", df_e$parliament_number, sep="") 

# TODO: we don't have the data for region rn
df_e$country_name <- NA
df_e$province_name <- NA

# re-arrange and output
uk_lower_constituencies <- df_e %>%
  select(observation_path,
         chamber_path,
         constituency_path,
         parliament_path,
         observation_number,
         chamber_number,
         constituency_number,
         parliament_number,
         chamber_name,
         constituency_name,
         country_name,
         province_name)

###############
# write csv
###############
setwd("~/Documents/GitHub/CompLegFall2019/data/uk_lower/Output")
# write.csv(uk_lower_constituencies, "uk_lower_constituencies.csv")


