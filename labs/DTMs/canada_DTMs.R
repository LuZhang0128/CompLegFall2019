#######################
# set working directory
# load data
# and load libraries
#######################

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

# Jeff wd
setwd('~/Documents/GitHub/CompLegFall2019/data/canadaTextParsing/Examples/')

# load libraries
pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg)) 
    install.packages(new.pkg, dependencies = TRUE)
  sapply(pkg, require, character.only = TRUE)
}

lapply(c("quanteda", "stringr", "tm"), pkgTest)

# load speeches data from 38th parliament
speechesDF <- read.csv("canada_floor_speeches.csv", stringsAsFactors = F, encoding = "UTF-8")

###################################
# create function to clean speeches
# to create DTM
###################################

clean_text <- function(inputVec){
    # lowercase
    tempVec <- tolower(inputVec)
    # remove everything that is not a number or letter
    tempVec <- str_replace_all(tempVec,"[^a-zA-Z\\s]", " ")
    # make sure all spaces are just one white space
    tempVec <- str_replace_all(tempVec,"[\\s]+", " ")
    # remove blank words
    tempVec <- tempVec[which(tempVec!="")]
    #browser()
    # tokenize (split on each word)
    tempVec <- str_split(tempVec, " ")[[1]]
    # create function for removing stop words
    remove_words <- function(str, stopwords) {
      x <- unlist(strsplit(str, " "))
      x <- x[!x %in% stopwords]
      # remove single letter words
      return(x[nchar(x) > 1])
    }
    
    # remove stop words
    tempVec <- remove_words(tempVec, stopwords("english"))

    # get count of each word in "document"
    count_df <- data.frame(document=row, 
                           count=rle(sort(tempVec))[[1]],
                           word=rle(sort(tempVec))[[2]])
    return(count_df)
}

# create new vector that we will continuously append via rbind
# probably not the most computationally efficient way to do this...
all_words <- NULL
# loop over all rows in original DF of speeches
for(row in 1:dim(speechesDF)[1]){
  all_words <- rbind(all_words, clean_text(speechesDF[row, "paragraph_text"]))
}
# find unique words in word matrix
unique(all_words$word)
# there are 676 unique words in corpus

###################################
# create open DTM filled w/ zeroes
###################################

DTM <- matrix(0, nrow=dim(speechesDF)[1], ncol=length(unique(all_words$word)))
# assign column names of DTM to be the unique words (in alpha order)
colnames(DTM) <- unique(all_words$word)
# loop over each "document"/paragraph
for(document in 1:dim(speechesDF)[1]){
  # find all the words that are used in that paragraph
  document_subset <- all_words[which(all_words$document==document),]
  # loop over each word
  for(row in 1:dim(document_subset)[1]){
    # and check which column it's in
      DTM[document, which(colnames(DTM)==document_subset[row, "word"] )] <- all_words[row, "count"]
  }
}

# compare how we did
# first look at DTM for 50th observation
which(DTM[50,]>0)
speechesDF[50,"paragraph_text"]

##################################
# Doing this all using library(tm)
##################################

# create new corpus object with tm
speech_corpus <- Corpus(VectorSource(speechesDF$paragraph_text))

# clean corpus as we did before
speech_corpus <- tm_map(speech_corpus, content_transformer(tolower))
speech_corpus <- tm_map(speech_corpus, removeNumbers)
speech_corpus <- tm_map(speech_corpus, removePunctuation)
speech_corpus <- tm_map(speech_corpus, removeWords, c("the", "and", stopwords("english")))
speech_corpus <- tm_map(speech_corpus, stripWhitespace)

# create DTM
alternative_DTM <- DocumentTermMatrix(speech_corpus)

# check to see what it looks like
inspect(alternative_DTM[1:50, 1:50])
