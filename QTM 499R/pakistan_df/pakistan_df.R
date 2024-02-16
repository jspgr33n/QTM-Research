#---------------------------------------------------------------------------#
#-------------------------SET UP WORKING ENVIRONMENT------------------------#
#---------------------------------------------------------------------------#

library(tesseract)
library(pdftools)
library(tidyverse)
library(dplyr)
library(stringr)
library(ggplot2)
library(lubridate)

# Directory to QTM 499R Folder in OneDrive
onedrive         <- "/Users/jspgr33n/Library/CloudStorage/OneDrive-EmoryUniversity/QTM-Research/QTM 499R"
rawdata_onedrive_pk <- paste0(onedrive, "/pakistan_df")

#---------------------------------------------------------------------------#
#-------------------50 RANDOM PAKISTAN NGOs FOR NGOBASE---------------------#
#---------------------------------------------------------------------------#

# NGOBase has 147 pages with around 10 NGOs on each page.
page_number <- sample(1:147,50, replace = TRUE)
list_number <- sample(1:10,50, replace = TRUE)

# Did not set seed prior to writing the csv so results will differ, but seed
# will be set to 499 henceforth.
set.seed(499)
ngobase_validity <- data.frame(page_number, list_number)
write.csv(ngobase_validity, paste0(rawdata_onedrive_pk,"/ngobase_validity.csv"))

ngobase_validity_websites <- read.csv(paste0(rawdata_onedrive_pk,"/ngobase_validity_websites.csv"))

# Count how many NGOs have websites
website_found_count <- ngobase_validity_websites %>%
  filter(website_found == "Yes") %>%
  nrow()

# Calculate percentage of websites found given 50 random NGOs
website_found_count/nrow(ngobase_validity_websites)
