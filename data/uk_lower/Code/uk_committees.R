############################
# detach and load packages
############################
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

lapply(c("stringr", "dplyr", "plyr", "tidyverse", "rvest", "zoo", "XML", "tidyr", "lubridate"), pkgTest)

##########################
# set working directory 
# import dataset
# create raw dataset
##########################
# set working directory
setwd('~/Documents/GitHub/CompLegFall2019/data/uk_lower/raw_characteristics/')

# read in dataset
files <- list.files(pattern="*.xml", full.names=TRUE, recursive=FALSE)

# to list
# if you want more information, just unmute the other lines of code and change the "ToDataFrame" to "ToList" 
committees <- xmlToList(xmlParse(files[1]))
# constituencies <- xmlToDataFrame(files[2])
# experiences <- xmlToDataFrame(files[3])
# governmentPosts <- xmlToDataFrame(files[4])
# interests <- xmlToDataFrame(files[5])
# oppositionPosts <- xmlToDataFrame(files[6])
# parliamentaryPosts <- xmlToDataFrame(files[7])
# parties <- xmlToDataFrame(files[8]) 
# staff <- xmlToDataFrame(files[9]) 

##################################
# make the dataframe that we want 
##################################
 nullToNA <- function(x) {
   if(is.null(x)){
     x <- NA
   } else {
     x <- x
   }
 }

 for (i in 1:length(committees)) {
  ListAs <- committees[[i]]$ListAs
  LayingMinisterName <- committees[[i]]$LayingMinisterName
  House <- committees[[i]]$House
  member_id <- committees[[i]][[".attrs"]]["Member_Id"]
  ListAs <- nullToNA(ListAs)
  LayingMinisterName <- nullToNA(LayingMinisterName)
  House <- nullToNA(House)
  member_id <- nullToNA(member_id)
  for (j in 1:length(committees[[i]]$Committees)) {
    committee_name <- committees[[i]]$Committees[[j]]$Name
    start_date <- committees[[i]]$Committees[[j]]$StartDate
    end_date <- committees[[i]]$Committees[[j]]$EndDate
    chair_date <- committees[[i]]$Committees[[j]]$ChairDates
    committee_id <- committees[[i]]$Committees[[j]][[".attrs"]]["Id"]
    committee_name <- nullToNA(committee_name)
    start_date <- nullToNA(start_date)
    end_date <- nullToNA(end_date)
    committee_id <- nullToNA(committee_id)
    if (!is.null(chair_date)){
      for (k in 1:length(chair_date <- committees[[i]]$Committees[[j]]$ChairDates)){
        chair_startDate <- committees[[i]]$Committees[[j]]$ChairDates[[k]]$StartDate
        chair_endDate <- committees[[i]]$Committees[[j]]$ChairDates[[k]]$EndDate
        observation <- data.frame(full_name = ListAs,
                                  House = House,
                                  member_id = member_id,
                                  committee_name = committee_name,
                                  start_date = start_date,
                                  end_date = end_date,
                                  chair_startDate = chair_startDate,
                                  chair_endDate = chair_endDate,
                                  committee_id = committee_id)
        out <- rbind(out, observation)
      }
    } else {
      chair_startDate <- NA
      chair_endDate <- NA
      observation <- data.frame(full_name = ListAs,
                                House = House,
                                member_id = member_id,
                                committee_name = committee_name,
                                start_date = start_date,
                                end_date = end_date,
                                chair_startDate = chair_startDate,
                                chair_endDate = chair_endDate,
                                committee_id = committee_id)
      if (i==1 && j==1) {
        out <- observation
      } else {
        out <- rbind(out, observation)
      }
    } 
  }
 }

#######################
# clean the dataframe
# create committee
#######################

## the data is good enough that i dont want to write any comments :(((( tooo lazy rn
# we still dont have the house of the committee
# sad news
# what is the government doing why are the names not consistent with each other?????
# if you want to get access to another set of names of the committees WITH house information, just run the abandoned.r
df <- out
rownames(df) <- c()
df_a <- df %>%
  select(committee_name, committee_id, House) %>%
  group_by(committee_name, House) %>%
  count()

df_b <- df %>%
  select(committee_name, committee_id) %>%
  mutate(committee_id = as.numeric(committee_id)) %>%
  unique %>%
  na.omit()
df_b$committee_number <- df_b$committee_id
rownames(df_b) <- c()
df_b$observation_number <- rownames(df_b)

df_b$committee_path <- paste(df_b$chamber_path,"/committee-",df_b$committee_number,sep="") 
df_b$observation_path <- paste(df_b$committee_path,"/observation-",df_b$observation_number,sep="")

uk_committees <- df_b %>%
  select(observation_path,
         # chamber_path,
         committee_path,
         observation_number,
         # chamber_number,
         committee_number,
         committee_name)

setwd('~/Documents/GitHub/CompLegFall2019/data/uk_lower/Output')
# write.csv(uk_committees, "uk_committees.csv")

###############################
# create committee membership
###############################
df <- out
rownames(df) <- c()
df_aa <- df %>%
  mutate(position = !is.na(chair_startDate)) %>%
  unique()
df_aa$position[df_aa$position==TRUE] <- "Chair"
df_aa$position[df_aa$position==FALSE] <- "Member"
df_aa$end_date[df_aa$end_date=="true"] <- NA
df_aa$start_date <- gsub("T00:00:00","",df_aa$start_date)
df_aa$end_date <- gsub("T00:00:00","",df_aa$end_date)
df_aa$chair_startDate <- gsub("T00:00:00","",df_aa$chair_startDate)
df_aa$chair_endDate <- gsub("T00:00:00","",df_aa$chair_endDate)

## get the parliment number
df<- df_aa %>%
  mutate(start_term = as.factor(start_date)) %>%
  mutate(end_term = as.factor(end_date))

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
sett1$freq[is.na(sett1$freq)]=1

colnames(sett1)

# expand the data frame to one entry for each parliament
df_ac <- sett1 %>%
  uncount(weights = freq, .id = "n", .remove = F) %>%
  mutate(parliament_number = start+n-1) %>%
  select(full_name,
         House,
         committee_name,
         start_date,
         end_date,
         chair_startDate,
         chair_endDate,
         committee_id,
         position,
         parliament_number)

# oberservation number
rownames(df_ac) <- c()
df_ac$observation_number <- rownames(df_ac)

df_ad <- df_ac %>%
  separate(full_name, c("last_name", "first_name"), ", ")
df_ad$full_name <- paste(df_ad$first_name, df_ad$last_name)

# read in membership.csv and costituency.csv
setwd('~/Documents/GitHub/CompLegFall2019/data/uk_lower/Committee')
membership <- read.csv("uk_lower_members.csv")

# merge them with current committee dataset
df_ba <- merge(df_ad, membership, by=c("first_name", "last_name"), all.x=T)
colnames(df_ba)

# select the information that we want
df_ca <- df_ba %>%
  select(committee_name,
         committee_id,
         full_name.x,
         member_number,
         member_path,
         constituency_ID,
         constituency_name,
         position,
         start_date.x,
         end_date.x,
         chair_startDate,
         chair_endDate,
         parliament_number,
         chamber_number)

# final clean up
colnames(df_ca) <- c("committee_name",
                      "committee_number",
                      "member_name",
                      "member_number",
                      "member_path",
                      "constituency_path",
                      "constituency_name",
                      "position",
                      "start_date",
                      "end_date",
                      "chair_startDate",
                      "chair_endDate",
                      "parliament_number",
                      "chamber_number")
df_ca$position[is.na(df_ca$start_date)] <- NA

# sort first by parliment_number, then by committee_number, then by member_number
df_cb <- df_ca[order(as.numeric(df_ca$parliament_number), as.numeric(df_ca$chamber_number), as.numeric(df_ca$committee_number), as.numeric(df_ca$member_number)), ]
rownames(df_cb) <- c()
df_cb$observation_number <- rownames(df_cb)

# set path
df_cb$parliament_path <- paste("/parliament-",df_cb$parliament_number,sep="") 
df_cb$chamber_path <- paste(df_cb$parliament_path,"/chamber-",df_cb$chamber_number,sep="") 
df_cb$committee_path <- paste(df_cb$chamber_path,"/committee-",df_cb$committee_number,sep="") 
df_cb$member_path <- paste(df_cb$committee_path,"/member-",df_cb$member_number,sep="") 
df_cb$observation_path <- paste(df_cb$member_path,"/observation-",df_cb$observation_number,sep="") 

uk_committees_membership <- df_cb %>%
  select(observation_path,
         parliament_path,
         chamber_path,
         committee_path,
         member_path,
         observation_number,
         chamber_number,
         parliament_number,
         committee_number,
         member_number,
         committee_name,
         member_name,
         member_path,
         constituency_name,
         constituency_path,
         position,
         start_date,
         end_date,
         chair_startDate,
         chair_endDate)

# write output
setwd('~/Documents/GitHub/CompLegFall2019/data/uk_lower/Output')
# write.csv(uk_committees_membership, "uk_committees_membership.csv")







