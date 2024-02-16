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
rawdata_onedrive <- paste0(onedrive, "/pakistan_df")

#---------------------------------------------------------------------------#
#-------------------50 RANDOM PAKISTAN NGOs FOR NGOBASE---------------------#
#---------------------------------------------------------------------------#

# NGOBase has 147 pages with around 10 NGOs on each page.
page_number <- sample(1:147,50, replace = TRUE)
list_number <- sample(1:10,50, replace = TRUE)

ngobase_validity <- data.frame(page_number, list_number)
write.csv(ngobase_validity, paste0(rawdata_onedrive,"/ngobase_validity.csv"))
