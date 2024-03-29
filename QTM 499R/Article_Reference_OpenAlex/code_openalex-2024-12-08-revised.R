
#------------------------------------------------------------------------------#
#----------------------- PART I. SETUP WORKING ENVIRONMENT --------------------#
#------------------------------------------------------------------------------#

#-----clean the workspace
rm(list=ls())
gc()

library(openalexR)
library(tidyverse)
library(jsonlite)
library(splitstackshape)

#----- Setup working directory
dir  <-"/Users/ellendong/Desktop/Dr. Alejandro Research Work/"
#dir  <- paste0("/Users/asanc31/Library/CloudStorage/",
#               "OneDrive-EmoryUniversity/Research assistant/expert_data/")
#dir  <- paste0("/Users/asanc31/Library/CloudStorage/",
#          "OneDrive-EmoryUniversity/Research assistant/expert_data/")
#dir <- "C:/Users/asanc/OneDrive - Emory University/Research assistant/expert_data/"

#------------------------------------------------------------------------------#
#------------------------- PART II. COLLECT DATA ------------------------------#
#------------------------------------------------------------------------------#

#---- (i) Obtain expert article information from external WebOfScience Data.
#--- import expert data
#--- convert DOIs to lower case (OpenAlex format), add indicator for missing DOI
#--- create variable to store openalexid, batch number and number of references
#--- exclude articles that have "Retracted" in the title
#--- obtain articles with a distinct title
#--- compute total number of articles
#--- compute total number of articles with a DOI
experts       <- as_tibble(read.csv(file = paste0(dir,
                                                "academicexpert_articles.csv"))) %>%
                 mutate(DOI = tolower(DOI),
                        has_DOI = case_when(!is.na(DOI) ~ 1,TRUE ~ 0)) %>%
                 mutate(batch_openalex   = as.integer(NA),
                        openalex_id      = toString(NA),
                        openalex_doi     = toString(NA),
                        num_ref_openalex = as.integer(NA),
                        openalex_title   = toString(NA)) %>%
                        filter(!grepl("Retracted",ArticleTitle)) %>%
                        distinct(ArticleTitle,DOI,.keep_all = TRUE)
experts_DOI   <- experts %>% filter(has_DOI == 1)
experts_noDOI <- experts %>% filter(has_DOI == 0)
nrow(experts)
nrow(experts %>% filter(has_DOI == 1))

#---- (ii) Obtain data from OpenAlex

#---- setup batch size
#---- compute total number of batches
#---- create tibble with subset of data
#---- compute total number of articles
#---- create empty tibble to store BASIC reference information
#---- create empty tibble to store DETAILED reference information
#---- create empty tibble to store ALL the reference data
batch_size          <- 50
subset_experts_data <- experts_DOI
num_total_article   <- nrow(subset_experts_data)
num_batch           <- num_total_article/batch_size
df_ref_combine      <- tibble() # aggregate result of referenced work and author id of original work
ref_au_combine      <- tibble() # aggregate result of author id of referenced work 
df_ref_batch_all    <- tibble() # integral final total result of these codes 

#---- record time at start of loop
#---- initialize batch_index
startTime   <- Sys.time()
batch_index <- 1
j           <- 1

for (j in seq(1,num_total_article,batch_size)){

  #----- print batch number
  #----- print first number in batch sequence
  #----- subset data of experts 
  #----- check whether it reaches the last batch
  #----- if it reaches the last batch, we will change the end number to be 4091 
  print(paste0("batch_",batch_index))
  print(paste0("seq",j))
  if(batch_index > num_total_article/batch_size-1){
    experts_batch <- subset_experts_data[j:num_total_article,]
  }else{
    experts_batch <- subset_experts_data[j:(j+batch_size-1),]
    
    print(num_total_article)
  }
  
  #-----------------------------------------------------------------------------
  #----------------------------------- (a) OBTAIN ARTICLE METADATA FROM OPENALEX
  #-----------------------------------------------------------------------------
  
  #------ initialize a tibble to store values
  #------ obtain a string vector with the DOIs
  #------ call the OpenAlex API with list of DOI
  #------ create a boolean vector for which DOIs that were NOT returned by API
  #------ obtain list of missing DOIs
  doi_batch           <- experts_batch$DOI
  filter_batch        <- oa_fetch(doi = doi_batch) %>%
                         mutate(DOI = gsub("https://doi.org/","",doi),
                                openalex_doi = doi)
  missing_boolean_vec <- !(paste0("https://doi.org/",doi_batch) %in%
                             filter_batch$doi)
  missing_DOI         <- doi_batch[missing_boolean_vec]
  
  #------ GOAL: Try to search articles by title if DOI not found.
  #------ obtain a vector of article titles in batch
  #------ replace commas in title_batch: Avoids errors in "oa_fetch()"
  #------ create a vector of missing article titles
  #------ run a loop over missing articles if 
  # obtain 
  title_batch         <- experts_batch$ArticleTitle
  title_batch_gsub    <- gsub(",","",experts_batch$ArticleTitle)
  missing_titles      <- title_batch_gsub[missing_boolean_vec]
  if(length(missing_DOI) >=1 ){
    for(k in 1:length(missing_DOI)){
      #------ extract record of article with that title
      #------ extract PublicationYear of article from "experts" data
      #------ extract DOI of article from "experts" data
      #------ call API search for missing article title
      #------ create new variables with publication year, DOI, openalex_doi
      #------ subset to records that match the pubication year
      #------ create variables for row_number, then extract first row
      #------ NOTE: The search might produce multiple records - select only one
      experts_record <- experts %>%
                        filter(ArticleTitle == title_batch[missing_boolean_vec])
      year_article   <- experts_record$PublicationYear
      DOI_article    <- experts_record$DOI
      fixed_records  <- oa_fetch(title.search = missing_titles[k]) %>%
                        mutate(PublicationYear = substr(publication_date,1,4),
                               DOI = DOI_article,
                               openalex_doi = doi) %>%
                        filter(PublicationYear == year_article) %>%
                        mutate(r = row_number()) %>% 
                        filter(r == 1)
      filter_batch   <- bind_rows(filter_batch,fixed_records)
     }
  }
  
  #------ GOAL: Save OpenAlex to original dataset.
  #------ create OpenAlex variables in "filter_batch" to math experts data
  #------ compute total number of nonmissing references by row-- with "rowwise()"
  #------ use "rows_update" to update specific rows of "experts" data
  #------ first update rows to include batch information
  #------ Then we update base on a few key columns of "filter_batch".
  #------ NOTE: The command "rows_update" ensures that we only update this batch.
  #------ This works like a "left_join" but only for a subset of the rows.
  filter_batch <- filter_batch %>%
                  mutate(openalex_id = id,
                         openalex_title = display_name) %>%
                  rowwise() %>% 
                  mutate(num_ref_openalex = sum(!is.na(referenced_works)))
  experts      <- rows_update(experts,
                              experts_batch %>% 
                              mutate(batch_openalex = batch_index),
                              by = "DOI")
  experts      <- rows_update(experts,
                              filter_batch %>% 
                              select(openalex_id,
                                       openalex_title,
                                       openalex_doi,
                                       num_ref_openalex,
                                       DOI),
                              by = "DOI")
  
  #------ subset experts batch
  # subset_experts_batch <- experts %>% filter(batch_openalex == 1)
  
  #-----------------------------------------------------------------------------
  #------------------------------------ (b) PREPARE REFERENCES DATA FOR API CALL
  #-----------------------------------------------------------------------------
  
  #------ select certain columns of "filter_batch"
  #------ subset a tibble with referenced_works
  #------ create_empty tibble to store batch information for references
  #------ loop over every article in the batch that was found in OpenAlex.
  filter_batch        <- filter_batch %>% select(id,author,doi,
                                         referenced_works,
                                          publication_date,
                                          display_name)
  df_references       <- filter_batch %>% select(referenced_works)
  df_ref_batch        <- tibble()
  for (i in 1:nrow(filter_batch)){
    print(paste0(batch_index,"_in_batch_",i))
    
    #------ extract vector of referenced works for each article
    #------ extract string of authors for each article
    #------ convert references vector to empty vector if has an NA.
    references   <- unlist(filter_batch[i,"referenced_works"][[1]]) 
    arti_auid    <- paste(filter_batch[['author']][[i]]$au_id,collapse=",")
    if(sum(is.na(references))>0){
      references <- character(0)
      # append(null_ref,doi_batch[i])
      print("There is a null ref")
    }
    #------ compute total number of references
    #------ repeat author string times num_ref
    #------ repeat openalex_id by num_ref
    #------ compute article-specific tibble with relevant info
    num_ref         <- length(references)
    rep_arti_auid   <- rep(arti_auid, times = num_ref)
    rep_openalexid  <- rep(filter_batch$id[i],times=num_ref)
    df_ref          <- tibble(openalex_id = rep_openalexid,
                              ref_openalex_id =references,
                              arti_audi = rep_arti_auid)
    df_ref_batch <-bind_rows(df_ref_batch,df_ref)
  }

  df_ref_combine <- bind_rows(df_ref_combine,df_ref_batch)
  
  #-----------------------------------------------------------------------------
  #----------------------------------- (c) OBTAIN ARTICLE METADATA FROM OPENALEX
  #-----------------------------------------------------------------------------
  
  #------ define batch size to extract information about references
  #------ extract unique list of references in this batch, convert to matrix
  #------ compute total number of unique references
  #------ initialize batch index
  #------ create empty tibble to store DETAILED info about references.
  size         <- 50
  list_ref_unique <- distinct(df_ref_batch %>% select(ref_openalex_id)) %>% as.matrix()
  row_refbatch    <- nrow(list_ref_unique)
  ref_batch_index <- 1
  refer_au_batch  <- tibble()
  #------ loop over unique references
  for (i in seq(1,row_refbatch,size)){
    if(i > (row_refbatch-size)){
      gap <- row_refbatch-i
    }else{
      gap <- size-1
    }
    #------ call API with a unique list of references for each batch
    #------ append results to current "refer_au_batch" data
    #------ select columns "id" (OpenAlexID) and author (which is a tibble)
    #------ create new variables, to be filled later.
    #------ delete "id" column
    refer_au       <- oa_fetch(identifier = list_ref_unique[i:(i+gap)])
    refer_au_batch <- bind_rows(refer_au_batch,
                                refer_au %>% select(id, author) %>% 
                                   mutate(ref_openalex_id = id,
                                          list_authorids = NA,
                                          list_authornames = NA,
                                          ref_batch_openalex = ref_batch_index ) %>%
                                  select(-id))
    
    #------ print basic information about references batches
    #------ update counter for reference batch index
    print(paste0("Batch :",batch_index, ", Ref_batch: ",ref_batch_index,
                 ", Ref_batch_size: ", length(df_ref_batch$ref_openalex_id[i:(i+gap)]),
                 ", Unique_refs:", nrow(refer_au)))
    ref_batch_index <- ref_batch_index + 1
  }

  #------ loop over different references
  #------ extract a string of author OpenAlex IDs comma separated
  #------ extract a string of author names comma separated
  #------ use "bind_rows" to append information to larger reference dataset.
  #for(k in 1:nrow(refer_au_batch)){
  #  print(k)
  #  refer_au_batch$list_authorids[k] <- paste(refer_au_batch[['author']][[k]]$au_id,collapse=",")
  #  refer_au_batch$list_authornames[k] <- paste(refer_au_batch[['author']][[k]]$au_display_name,collapse=",")
 # }
  # ref_au_combine <- bind_rows(ref_au_combine,refer_au_batch)

  #------ Fix the error from line 258-261
  #------ Check the structure for the first few "author" entries
  #------ Try to modify the loop to handle different data type if there is any
  str(refer_au_batch[['author']][1:5])
  list_id_issues <- c()
  
  for(k in 1:nrow(refer_au_batch)){
    
    # Check if 'author' is a list and has the 'au_id' element
    if(is.list(refer_au_batch[['author']][[k]]) && !is.null(refer_au_batch[['author']][[k]]$au_id)){
      refer_au_batch$list_authorids[k] <- paste(refer_au_batch[['author']][[k]]$au_id, collapse=",")
      refer_au_batch$list_authornames[k] <- paste(refer_au_batch[['author']][[k]]$au_display_name, collapse=",")
    } else {
      # Handle cases where 'author' is not a list or does not contain 'au_id'
      print(k)
      refer_au_batch$list_authorids[k] <- NA
      refer_au_batch$list_authornames[k] <- NA
      list_id_issues <- c(list_id_issues,k)
    }
  }
  
  list_id_issues
  
  test_batch <- refer_au_batch[list_id_issues,]

  
  #------ update_batch_index
  #------ merge unique reference information into article database
  #------ write ".csv" file with larger dataset, stamping batch size
  #------ write ".csv" file without stamping batch size
  batch_index      <- batch_index+1
  df_ref_batch_all <- left_join(df_ref_combine,
                                distinct(ref_au_combine,ref_openalex_id,.keep_all =TRUE), 
                                by = c('ref_openalex_id' = 'ref_openalex_id'))
  write.csv(as.matrix(df_ref_batch_all),
            paste0("12.8midcheck_size",
                   batch_size,"_","aritclefrom_",j,"_", batch_index, ".csv"),
            row.names = FALSE)
  write.csv(as.matrix(df_ref_batch_all),
            paste0("12.8midcheck_size_all", ".csv"),
            row.names = FALSE)
}

endTime <- Sys.time()
print(endTime - startTime)

#------------------------------------------------------------------------------#
#------------------- PART III. DESCRIPTIVE STATISTICS AND DIAGNOSTIC ----------#
#------------------------------------------------------------------------------#

#------------------------------------------------------------------------------#
#------------ (i) Basic Accounting --------------------------------------------#
#------------------------------------------------------------------------------#

#------ How many artciles have/don't have a DOI?
nrow(experts_DOI)
nrow(experts_noDOI)

#------ How many articles have a DOI we couldn't find them in Open Alex?
nrow(experts %>% 
       mutate(DOI_string = paste0("https://doi.org/",tolower(DOI))) %>% 
       filter(has_DOI == 1,DOI_string != openalex_doi,
              !is.na(batch_openalex) ))

#------ How many articles have a DOI, we couldn't find them by DOI on OpenAlex, 
#------ but we found them via their article title?
nrow(experts %>% 
       mutate(DOI_string = paste0("https://doi.org/",tolower(DOI))) %>% 
       filter(has_DOI == 1,DOI_string != openalex_doi,
              !is.na(batch_openalex), !is.na(openalex_id)))

#------ verify that preliminary count of references coincides with ref database
sum(experts$num_ref_openalex,na.rm = TRUE)
nrow(df_ref_batch_all)

#------ verify that unique references overall, coincide with "ref_au_combine"
length(unique(ref_au_combine$ref_openalex_id))
length(unique(df_ref_batch_all$ref_openalex_id))

#------ verify all the "graph edges" between articles are unique
final_distinct <- distinct(df_ref_batch_all, openalex_id,
                           ref_openalex_id, .keep_all = TRUE) 
nrow(final_distinct)
nrow(df_ref_batch_all)

#------------------------------------------------------------------------------#
#------------ (ii) Descriptives -----------------------------------------------#
#------------------------------------------------------------------------------#

#------ How many articles with a DOI don't have any references?
sum(experts$num_ref_openalex == 0,na.rm = TRUE)

#------ how many references are there per article?
hist(experts$num_ref_openalex,breaks = 40)

#------ GOAL: How many references are there to articles inside our dataset?
#------ compute unique list of openalex IDs
#------ create new variable indicate whether the reference is part of our dataset
#------ Use "group_by"/"mutate" to calculate number of "inner" references per row
#------ ungroup (to avoid unexpected results in the code later)
list_openalex_ids <- unique(df_ref_batch_all$openalex_id)
df_ref_batch_all  <- df_ref_batch_all %>%
  mutate(dummy_ref_inner = case_when(ref_openalex_id %in% list_openalex_ids ~ 1,
                                     TRUE ~ 0)) %>%
  group_by(openalex_id) %>% mutate(num_ref_openalex_inner = sum(dummy_ref_inner)) %>%
  ungroup()
table(df_ref_batch_all$num_ref_openalex_inner)
hist(df_ref_batch_all$num_ref_openalex_inner, breaks = 40)

#------ GOAL: Do the OpenAlex references align with the WoS references?
#------ Run a linear regression of OpenAlexNumReferences with WoSNumReferences
#------ Plot the two variable
lm(experts$num_ref_openalex ~ experts$CitedReferenceCount,)
plot(experts$CitedReferenceCount,experts$num_ref_openalex)
