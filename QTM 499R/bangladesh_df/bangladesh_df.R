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
rawdata_onedrive <- paste0(onedrive, "/bangladesh_df/new_files")

#---------------------------------------------------------------------------#
#-------------------------ITERATION & INCREMENTING--------------------------#
#---------------------------------------------------------------------------#

# Loading Bangladesh datasets
bangladesh_local <- read.csv(paste0(rawdata_onedrive, 
                                    "/bangladesh_local_ngo_list.csv"))
bangladesh_international <- read.csv(paste0(rawdata_onedrive, 
                                            "/bangladesh_foreign_ngo_list.csv"))

# Iterating through each row in Bangladesh local dataset and assigning
# values to each NGO
count <- 1

for (i in 1:nrow(bangladesh_local)) {
  # Check if the cell is empty (NA or blank)
  if (is.na(bangladesh_local[i, "num_var"]) || 
      bangladesh_local[i, "num_var"] == "") {
    # Replace the empty cell with the current replacement value
    bangladesh_local[i, "num_var"] <- count
    # Increment the replacement value for the next empty cell
  }
  else {
    count <- as.numeric(bangladesh_local[i, "num_var"])
  }
}

# Iterating through each row in Bangladesh international dataset and 
# assigning values to each NGO
count <- 1

for (i in 1:nrow(bangladesh_international)) {
  # Check if the cell is empty (NA or blank)
  if (is.na(bangladesh_international[i, "num_var"]) || bangladesh_international[i, "num_var"] == "") {
    # Replace the empty cell with the current replacement value
    bangladesh_international[i, "num_var"] <- count
    # Increment the replacement value for the next empty cell
  }
  else {
    count <- as.numeric(bangladesh_international[i, "num_var"])
  }
}

#---------------------------------------------------------------------------#
#---------REMOVING NA VALUES AND CONFIRMING COLUMNS HAVE SAME NAMES---------#
#---------------------------------------------------------------------------#

bangladesh_international$reg_no <- ifelse(is.na(bangladesh_international$reg_no), "", bangladesh_international$reg_no)
bangladesh_local$reg_no <- ifelse(is.na(bangladesh_local$reg_no), "", bangladesh_local$reg_no)

colnames(bangladesh_local) <- colnames(bangladesh_international)

#---------------------------------------------------------------------------#
#-----------------CONCATENATING ROWS & DIFFERENTIATING TYPES----------------#
#---------------------------------------------------------------------------#

bangladesh_local <- bangladesh_local %>%
  group_by(num_var) %>%
  summarize(
    ngo_name = paste(ngo_name, collapse = " "),
    ngo_address = paste(ngo_address, collapse = " "),
    reg_no = paste(reg_no, collapse = " "),
    reg_date = paste(reg_date, collapse = " "),
    renewed_on = paste(renewed_on, collapse = " "),
    valid_until = paste(valid_until, collapse = " "),
    district = paste(district, collapse = " "),
    country = paste(country, collapse = " "),
    remarks = paste(remarks, collapse = " ")
  )

bangladesh_international <- bangladesh_international %>%
  group_by(num_var) %>%
  summarize(
    ngo_name = paste(ngo_name, collapse = " "),
    ngo_address = paste(ngo_address, collapse = " "),
    reg_no = paste(reg_no, collapse = " "),
    reg_date = paste(reg_date, collapse = " "),
    renewed_on = paste(renewed_on, collapse = " "),
    valid_until = paste(valid_until, collapse = " "),
    district = paste(district, collapse = " "),
    country = paste(country, collapse = " "),
    remarks = paste(remarks, collapse = " ")
  )

# Adding a new column "type" to show the dataset is local/international, 
bangladesh_local["type_ngo"] <- "local"
bangladesh_international["type_ngo"] <- "international"

#---------------------------------------------------------------------------#
#-------------COMBINING AND WRITING NEW DATASET INTO A CSV------------------#
#---------------------------------------------------------------------------#

# Combine both international and local Bangladesh datasets
# Row 8643 is where local changes to international
bangladesh_df <- rbind(bangladesh_local, bangladesh_international)
bangladesh_df <- bangladesh_df %>%
  mutate(reg_no = str_squish(reg_no),
         ngo_name = str_squish(ngo_name))

# Writing Bangladesh total dataset into a new csv file
write.csv(bangladesh_df, paste0(rawdata_onedrive,"/bangladesh_listngos_total.csv"))

#---------------------------------------------------------------------------#
#-----------CHECKING NGO UNIQUE IDS/DUPLICATES & SUMMARY STATS--------------#
#---------------------------------------------------------------------------#

# Check for identical reg_no and how many there are
# 7 reg_no are identical, 6 being in local dataset, 1 being a repeated reg_no
# in local and international
check_ngo_counts <- bangladesh_df %>%
  group_by(reg_no) %>%
  summarize(count = n()) %>%
  arrange(desc(count))

# Check to see if any NGOs have identical names and compare it to their reg_no
# 4 ngo_names are identical, but have different date values which may explain
# this repetition.
check_ngo_names <- bangladesh_df %>%
  group_by(ngo_name, reg_no) %>%
  summarize(count = n()) %>%
  arrange(desc(count))

# Making sure there are no repeated reg_no in local/international, respectively
# 6 reg_no's (1049, 1091, 1347, 2778, 486, 995) are repeated for local
# No reg_no's are repeated in international
bangladesh_df %>%
  filter(type_ngo == "local") %>%
  group_by(reg_no) %>%
  summarize(count = n()) %>%
  arrange(desc(count)) %>%
  filter(count == 2)

bangladesh_df %>%
  filter(type_ngo == "international") %>%
  group_by(reg_no) %>%
  summarize(count = n()) %>%
  arrange(desc(count)) %>%
  filter(count == 2)

# There are some NGOs that have the same names but are formatted differently
# 55 NGO_names are identical but there are 60 with identical reg_no's
# 3 reg_no's are repeated in the local dataset, but none in the international

# Picking 20 random rows in bangladesh_df to see if their data exists on the
# internet

# Setting seed for reproducability
set.seed(499)
random_20_rows <- bangladesh_df %>%
  sample_n(20) %>%
  arrange(ngo_name) %>%
  select(ngo_name, reg_no, type_ngo, remarks, valid_until)

# checking how many NGOs are missing a reg_no
# With new dataset, none are missing reg_no
bangladesh_df %>%
  filter(is.na(reg_no) | reg_no == "")

#---------------------------------------------------------------------------#
#--------------------CREATING GRAPHS AND DISTRIBUTIONS----------------------#
#---------------------------------------------------------------------------#

# squish string to make sure all countries and districts are the same
# (no extra spaces)
bangladesh_df <- bangladesh_df %>%
  mutate(district = str_squish(district),
         country = str_squish(country))

# changing the format of the date so it's readable with lubridate functions
bangladesh_df$reg_date <- as.Date(bangladesh_df$reg_date, format = "%d-%b-%y")
bangladesh_df$renewed_on <- as.Date(bangladesh_df$renewed_on, format = "%d-%b-%y")
bangladesh_df$valid_until <- as.Date(bangladesh_df$valid_until, format = "%d-%b-%y")

# making histograms for year counts based off different columns
reg_date_histogram <- bangladesh_df %>%
  mutate(year = year(reg_date)) %>%
  group_by(year) %>%
  summarize(count = n()) %>%
  ggplot(aes(x = year, y = count)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.9)) +
  geom_text(aes(label = count), vjust = -0.5, size = 3) +
  labs(title = "Histogram of Registration Date of NGOs in Bangladesh") +
  xlab("Registration Year") +
  ylab("Number of NGOs")

renewed_on_histogram <- bangladesh_df %>%
  mutate(year = year(renewed_on)) %>%
  group_by(year) %>%
  summarize(count = n()) %>%
  ggplot(aes(x = year, y = count)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.9)) +
  geom_text(aes(label = count), vjust = -0.5, size = 3) +
  labs(title = "Histogram of Renewal Date of NGOs in Bangladesh") +
  xlab("Renewed On Year") +
  ylab("Number of NGOs")

valid_until_histogram <- bangladesh_df %>%
  mutate(year = year(valid_until)) %>%
  group_by(year) %>%
  summarize(count = n()) %>%
  ggplot(aes(x = year, y = count)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.9)) +
  geom_text(aes(label = count), vjust = -0.5, size = 3) +
  labs(title = "Histogram of Expiration Date of NGOs in Bangladesh") +
  xlab("Expiration Year") +
  ylab("Number of NGOs")

# show district distribution within Bangladesh
# many districts within Bangladesh, histogram is a bit messy
bangladesh_df %>%
  filter(country == "Bangladesh") %>%
  group_by(district) %>%
  summarize(count = n()) %>%
  ggplot(aes(x = district, y = count)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.9)) +
  geom_text(aes(label = count), vjust = -0.5, size = 3) +
  labs(title = "Distribution of districts") + 
  theme(axis.text.x = element_text(angle = 50, hjust = 1))

# shows count of district distribution within Bangladesh
bangladesh_df %>%
  filter(country == "Bangladesh") %>%
  group_by(district) %>%
  summarize(count = n()) %>%
  arrange(desc(count))

# show distribution of countries
bangladesh_df %>%
  group_by(country) %>%
  summarize(count = n()) %>%
  ggplot(aes(x = country, y = count)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.9)) +
  geom_text(aes(label = count), vjust = -0.5, size = 3) +
  labs(title = "Distribution of countries") + 
  theme(axis.text.x = element_text(angle = 50, hjust = 1))

#---------------------------------------------------------------------------#
#--------------------REMOVING NGOs THAT HAVE EXPIRED------------------------#
#---------------------------------------------------------------------------#

# 10/31/2023

# Filtering out NGOs that have expired (their valid_until date has passed)
bangladesh_df_valid <- bangladesh_df %>%
  filter(valid_until > today())

# Create another 50 rows with the filtered dataset
set.seed(499)
random_50_rows_valid <- bangladesh_df_valid %>%
  sample_n(50) %>%
  arrange(ngo_name) %>%
  select(ngo_name, reg_no, type_ngo, remarks, valid_until)

# Write this into a csv file
write.csv(random_50_rows_valid, paste0(rawdata_onedrive, "/random_50_rows_valid.csv"))

#---------------------------------------------------------------------------#
#-------------------HYPERLINKING SEARCH LINKS FOR NGOs----------------------#
#---------------------------------------------------------------------------#

# 12/5/2023

# Preparing the ngo links for Google searches

google_prefix <- "https://www.google.com/search?q="

# Copy df with bangladesh_df and add ngo_name hyperlinks and prefilled hyperlinks
bangladesh_df_valid_searches <- bangladesh_df_valid %>%
  mutate(ngo_name = ngo_name,
         text_ngo_name = paste0(google_prefix,ngo_name),
         text_ngo_name_words = paste0(google_prefix,ngo_name,"+NGO+Bangladesh")) %>%
  mutate(link_ngo_name = paste0("=HYPERLINK(\"",text_ngo_name,"\", \"", text_ngo_name,"\")"),
         link_ngo_name_words = paste0("=HYPERLINK(\"",text_ngo_name_words,"\", \"", text_ngo_name_words,"\")"))

class(bangladesh_df_valid_searches$text_ngo_name) <- "hyperlink"
class(bangladesh_df_valid_searches$text_ngo_name_words) <- "hyperlink"

# Export this newly created copy with hyperlinks for Amazon Turk usage
write.csv(bangladesh_df_valid_searches,
          row.names = FALSE,
          file = paste0(rawdata_onedrive, "/bangladesh_df_valid_searches.csv"))

#---------------------------------------------------------------------------#
#-------------------COUNTING NGO FIELDS FROM 50 SAMPLE----------------------#
#---------------------------------------------------------------------------#

# 12/12/2023

random_50_rows_valid_info <- bangladesh_local <- read.csv(paste0(rawdata_onedrive, 
                                                                 "/random_50_rows_valid_info.csv"))

random_50_rows_valid_info %>%
  group_by(ngo_field) %>%
  summarise(count = n())
