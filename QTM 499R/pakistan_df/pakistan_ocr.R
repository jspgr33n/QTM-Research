
# Last updated: February 24, 2024
# INSTRUCTIONS FOR JAMES:
# This document extracts data from a PDF of pakistan NGOs.
# It requires TWO manual inputs: (1) A parameter to rotate the PDF.
#                                (2) The coordinates of the table.
# Since each page in the PDF has a slightly different rotation and position
# then we have tweak this manually for each.
# Once we enter this information manually, I (Alejandro) have coded up
# an algorithm that automatically extracts the information.
#
# STRENGTHS: The algorithm seems to extract the names of organizations perfectly
#            now, and their respective numbers.
# WEAKNESSES: The MOU signing date is computed, but there are still some issues.
#           Overall, the code is very sensitive to how we define the coordinates. 
#           Please pay particular attention to how I defined the coordinates for
#           pages 1-2 and then do the same for pages 3-10.

####.
###
## WHAT TO FOCUS ON? SECTION III.
###
#
##


#
#------------------------------------------------------------------------------#
#------------------- I. SET UP WORKING DIRECTORY ------------------------------#
#------------------------------------------------------------------------------#

# Clean working environment
rm(list = ls())

# Import packages
library(tesseract)
library(magick)
library(magrittr)
library(tidyverse)
library(readxl)
# eng <- tesseract("eng")

# Set directory (automatically detecting computer)
# The first time you will need to enter this manually

# Changed from Dr. Sanchez-Becerra's directory to James' directory

if(Sys.info()["user"] == "jspgr33n") {
  dirhat     <- paste0("/Users/jspgr33n/Library/CloudStorage/",
                       "OneDrive-EmoryUniversity/QTM-Research/QTM 499R/pakistan_df/")
} else if(Sys.getenv("USERNAME")=="jspgr33n"){
  dirhat <- ""
} else if(Sys.info()["user"] == "asanc31"){
  dirhat     <- paste0("/Users/asanc31/Library/CloudStorage/",
                       "OneDrive-EmoryUniversity/QTM 499R/pakistan_df/")
}

# Set image directory
imagedir <- paste0(dirhat,"image_files")
setwd(imagedir) # This is where the PNG files will be stored.

# Define name of PDF
filename <- "pakistan_listngos_Website3.pdf"

# Convert PDF to separate PNG and store in "imagedir"
pngfile_list <-
  pdftools::pdf_convert(paste0(dirhat,filename), dpi = 600)


#------------------------------------------------------------------------------#
#------------- II. DEFINE SET OF CUSTOM FUNCTIONS FOR IMAGE PREPROCESSING -----#
#------------------------------------------------------------------------------#

#' This function reads a PNG from a file, then processes it
#' so that it is easier to read by OCR
#' @param image_filename The path of a file
#' @param rotate_param   A scalar parameter to rotate the image
#' output: a clean image
#' 
fn_clean_image <- function(image_filename,rotate_param){
  clean_image <- image_read(image_filename) %>%
    image_resize("2000") %>%                  # RESIZE             
    image_convert(colorspace = 'gray') %>%    # CHANGE COLOR TO GRAY
    image_trim() %>%                          # TRIM EDGES
    image_transparent(color = "white", fuzz=75) %>%  # REMOVE BLACK SPECKS
    image_background("white") %>%             # SET BACKGROUN COLOR TO WHITE
    image_rotate(rotate_param)                # ROTATE IMAGE SO THAT IT IS
                                              # EASIER TO RECOGNIZE TABLE
  return(clean_image)
}


#' This function crops an image
#' We use this to define the area of the image that contains the table (this
#' improves the quality of the OCR dramatically).
#' This function can also be uses to define specific boxes/cells within the
#' table.
#' @param image_object An image object, imported previously.
#' @param box_param    A list of 4 parameters specifying the coordinates
#'                     where the box starts, as well as the width and height.
#' output: A cropped image
#'  
#'  Note: The box param arguments are based on the position by pixels
fn_crop_image <- function(image_object,box_param){
  cropped_image <- image_object %>% 
    image_crop(geometry_area(width = box_param$width,
                             height = box_param$height,
                             box_param$hstart,   # Horizontal starting point
                             box_param$vstart))    # Vertical starting point
  return(cropped_image)
}

#' This function conducts OCR over an image
#' @param image_object An image object, imported previously.
#' @param box_param    A list of parameters specifying the coordinates
#'                     where the box starts, as well as the width and height.
#' output: a dataframe with the information extracted, and a cropped image
#'                      
fn_extract_column <- function(image_object,box_param){
  # Start by cropping the image
  cropped_image <- fn_crop_image(image_object,box_param)
  raw_text   <- cropped_image %>% image_ocr()
  raw_tibble <- raw_text %>% 
    str_split(pattern = "\n") %>% 
    unlist() %>%
    tibble(data = .) 
  if(nrow(raw_tibble) == 1){
    raw_tibble <- raw_tibble %>% as.data.frame()
  } else{
    raw_tibble <- raw_tibble %>% filter(data != "") %>% as.data.frame()
  }
  
  return(list(raw_tibble = raw_tibble,
              cropped_image = cropped_image))
}

#------------------------------------------------------------------------------#
#------------- III. INITIAL PROCESS IMAGE DATA --------------------------------#
#------------------------------------------------------------------------------#

all_data <- tibble()

for (set_page in 1:10) {

  # Import configuration data for each page
  config_data  <- read_excel(paste0(dirhat,"param/param_ocr.xlsx")) %>%
                  as.data.frame()
    
  # Initial Crop
  rotate_param       <- config_data[set_page,"rotate_param"]  # 0.75, stats for p1
  image_param        <- list()
  image_param$width  <- config_data[set_page,"width"]         # 1750 
  image_param$height <- config_data[set_page,"height"]        # 1950
  image_param$hstart <- config_data[set_page,"hstart"]        # 100  
  image_param$vstart <- config_data[set_page,"vstart"]        # 230  
  clean_image        <- fn_clean_image(image_filename = pngfile_list[set_page],
                                       rotate_param = rotate_param) 
  clean_image        <- fn_crop_image(image_object = clean_image,
                                      box_param = image_param)
  
  image_param
  
  ### JAMES INSTRUCTIONS:
  #  Tweak the values in the excel file until you make sure that
  # we can properly crop and rotate the image in each page
  
  # IMPORTANT: Double check in the PDF to make sure that the table 
  # starts in the right place
  # Some pages seem to have a higher rotation than others
  clean_image

#------------------------------------------------------------------------------#
#------------- IV. OCR --------------------------------------------------------#
#------------------------------------------------------------------------------#

  # Step 1
  box_param    <- list()
  box_param$width  = (image_param$width)*0.5
  box_param$height = image_param$height
  box_param$hstart = (image_param$width)*0.1
  box_param$vstart = 0
  
  results <- fn_extract_column(clean_image,box_param)
  results$cropped_image
  
  list_organization_names = results$raw_tibble[,1]
  total_rows = length(list_organization_names)
  
  # Step 2: Create Data to fill
  data <- tibble(box_value = rep(NA,total_rows), 
                 index = rep(NA,total_rows),
                 name = list_organization_names)
  
  # Step 3: Extract organization numbers
  
  # This is done to properly extract the names of organizations
  # that are written across more than one line.
  for(i in 1:total_rows){
    print(i)
    #i          <- 15
    box_param        <- list()
    box_param$width  <- (image_param$width)*0.07
    box_param$height <- (image_param$height / total_rows)
    box_param$hstart <- (image_param$width)*0.03
    box_param$vstart <- (i-1)*(image_param$height / total_rows)
    
    # Conduct OCR
    results <- fn_extract_column(clean_image,box_param)
    results$cropped_image
    
    # Extract value from box
    box_value   <- results$raw_tibble[1,1]
    
    # Extract numeric value from box
    regexp <- "[[:digit:]]+"      # This ensures that we only extract digits
    value  <- as.numeric(str_extract(box_value, regexp))
  
    if(i == 1){
      value = value
    } else{
      if(box_value == ""){
        value <- data[i-1,"index"]
      } else {
        value <- data[i-1,"index"] + 1
      }
    }
    
    data[i,"box_value"] <- box_value
    data[i,"index"]     <- value
  }
  
  # Process data to concatenate organization names that
  # are written across multiple rows
  data <- data %>% ungroup()
  data <- data %>% group_by(index) %>%
              summarise(box_value = paste(box_value,collapse = "|"),
              name = paste(name,collapse = " ")) %>% ungroup()
  
  data
  
  # Step 4: Extract expiration date
  box_param    <- list()
  box_param$width  = (image_param$width)*0.2
  box_param$height = image_param$height
  box_param$hstart = (image_param$width)*0.6
  box_param$vstart = 0
  results <- fn_extract_column(clean_image,box_param)
  results$cropped_image
  list_mou_signing = results$raw_tibble[,1]
  
  if( length(list_mou_signing) == nrow(data)){
    data$list_mou_signing <- list_mou_signing
  } else {
    print("Number of rows of MOU does not match")
  }
  
  # Step 5: Extract expiration date
  box_param    <- list()
  box_param$width  = (image_param$width)*0.18
  box_param$height = image_param$height
  box_param$hstart = (image_param$width)*0.8
  box_param$vstart = 0
  results <- fn_extract_column(clean_image,box_param)
  results$cropped_image
  list_mou_validity = results$raw_tibble[,1]
  
  if( length(list_mou_validity) == nrow(data)){
    data$list_mou_validity <- list_mou_validity
  } else {
    print("Number of rows of MOU validity does not match")
  }
  
  all_data <- bind_rows(all_data, data)
}

all_data

