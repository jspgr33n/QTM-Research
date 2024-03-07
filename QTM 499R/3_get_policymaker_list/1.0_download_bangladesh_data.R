#------------------------------------------------------------------------------#
# Download Bangladesh data
# Author: Joel Becker

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
  "dplyr",            # data cleaning
  "data.table",       # data read/write
  "tesseract"         # pdf OCR
)
new.packages <- packages[!(packages %in% installed.packages()[, "Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(packages, library, character.only = TRUE)

# package settings
eng <- tesseract("eng")

# directories
main_dir <- "codebase/"
data_dir <- paste0(main_dir, "raw_data/3_get_policymaker_list/")
temp_dir <- paste0(main_dir, "temp/3_get_policymaker_list/")
out_dir <- paste0(main_dir, "output/3_get_policymaker_list/")


########################################################
###################### Load data #######################
########################################################

data <- ocr_data(paste0(
  data_dir, "ngo_raw_lists/bangladesh_listngos_local_2020.pdf"
))

data <- ocr(paste0(
  data_dir, "ngo_raw_lists/bangladesh_listngos_local_2020.pdf"
))


########################################################
###################### Save data #######################
########################################################

path <- paste0(temp_dir, "bangladesh_listngos_local_2020.csv"
fwrite(data, path)

