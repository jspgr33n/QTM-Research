#------------------------------------------------------------------------------#
# Process expert list -- first round
# Author: Alejandro Sanchez, Joel Becker

# Notes:
#
#------------------------------------------------------------------------------#


########################################################
######################## Set-up ########################
########################################################

# clear wd
rm(list = ls())

# load libraries
packages <- c(
  "dplyr",        # Manage data cleaning
  "haven",            # Imports Stata database
  "readxl",           # Import excel files
  "splitstackshape",  # Clean columns with lists (e.g. authors, categories,etc)
  "bibtex",
  "bib2df",
  "rworldmap",
  "stringr",          # Special operations with strings
  "estimatr",
  "openxlsx",
  "tidyr",
  "tidyverse",
  "readr",
  "plyr",
  "feather", # Light data files
  "janitor", # Tidy tables
  "ggplot2"
)
new.packages <- packages[!(packages %in% installed.packages()[, "Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(packages, library, character.only = TRUE)

main_dir           <- "D:/GitHub/expert-forecasting"
raw_dir <- paste0(main_dir, "/raw_data/3_get_policymaker_list/ngo_india_scraping")
stored_dir <- paste0(main_dir, "/output/3_get_policymaker_list/")

list_rawfiles_ngo <- list.files(path=raw_dir, pattern="*.csv", full.names=TRUE)
# scraped_data <- ldply(list_rawfiles_ngo, read_csv,show_col_types = FALSE)
# write_csv(scraped_data,paste0(stored_dir,"scraped_data_ngos_india.csv"))

scraped_data <- as_tibble(read_csv(paste0(stored_dir,"/scraped_data_ngos_india.csv")))
names(scraped_data)

# Check for e-mail information
mean(!is.na(scraped_data$contact_details_email))
mean(1*(scraped_data$contact_details_email != "Not Available"),na.rm = TRUE)

# Check for website information
mean(!is.na(scraped_data$contact_details_website))
mean(1*(scraped_data$contact_details_website != "Not Available"),na.rm = TRUE)

# Clean data
scraped_data <- mutate_if(scraped_data,is.character, 
                          stringr::str_replace_all, pattern = "&amp;", 
                          replacement = "&")

#--------------------------- SUMMARY STATS FOR FULL DATASET -------------------#

# Count NGOs scraped by state
# This is useful as a quality diagnostic because sometimes the scraping
# algorithm does not complete the data extraction due to interrupted connections.
table_countngos_state  <- as_tibble(scraped_data %>%
  tabyl(sector_number, page_num)) %>%
  select("sector_number",paste0(1:194))

# Check a specific page (for diagnostic)
check_page <- scraped_data %>%
  filter(state_of_registration=="ANDHRA PRADESH",
         page_num == 12)
# Count NGOs by state
table_state <- tibble(statefreq = table(scraped_data$sector_number))


data_intermediate <-scraped_data %>%
  tabyl(state_of_registration, page_num)
sum(data_intermediate[10,-1] %>% as.matrix())

#--------------------------- SUBSET DATA BY ISSUES ----------------------------#

# Obtain list of key issues
key_issues_list <- unique(cSplit(scraped_data,
       splitCols=c("key_issues"),
       sep =",", direction="long",
       type.convert = FALSE) %>% select(key_issues))

subset_keyissues <- c("Micro Finance (SHGs)",
                      "Rural Development & Poverty Alleviation",
                      "Urban Development & Poverty Alleviation",
                      "Labour & Employment",
                      "Women's Development & Empowerment",
                      "Micro Small & Medium Enterprise")

# Draw a subset of maybes:
# "Health & Family Welfare",
# "Vocational Training",


adjacent_keyissues <- c("Micro Small & Medium Enterprise",
                        "Information & Communication Technology",
                        "Nutrition",
                        "Skill Development")
excluded_keyissues <- setdiff(unlist(key_issues_list), c(subset_keyissues,
                                                 adjacent_keyissues))
excluded_keyissues <- c("Sports","Not Available","Art & Culture",
                        "Aged/Elderly","Differently Abled",
                        "Drinking Water","Environmental & Forests",
                        "HIV/AIDS","Housing",
                        "Micro Small & Medium Enterprises",
                        "Tourism",
                        "Animal Husbandry",
                        "Dairying & Fisheries",
                        "Biotechnology",
                        "Prisoner's Issues",
                        "New & Renewable Energy",
                        "Tribal Affairs",
                        "Water Resources")

subset_ngos <- scraped_data %>%
  filter(grepl(paste0(subset_keyissues,collapse = "|"), key_issues)) %>%
  filter(!grepl(paste0(excluded_keyissues,collapse = "|"), key_issues))

subset_ngos  

#------------------------- Compute Descriptive Statistics ---------------------#
# When were NGOs founded?
hist(as.Date(subset_ngos$registration_date,format = c("%d-%m-%Y")),
     breaks = 50)

# What states do the NGOs belong to
ggplot(subset_ngos,aes(x=state_of_registration)) +
  geom_bar() +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))

#ggplot(scraped_data,aes(x=state_of_registration)) +
#  geom_bar() +
#  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))

# How many of them list a website
mean(1*(subset_ngos$contact_details_website != "Not Available"),na.rm = TRUE)

table(subset_ngos$type_of_ngo)


write_csv(subset_ngos,paste0(stored_dir,"subset_ngos_india.csv"))
