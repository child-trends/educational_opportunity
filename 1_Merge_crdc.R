##############################################################
# Project: USALEEP                                           #
# Purpose: Merge 2011-12,2013-14 and 2015-15 data from  CRDC #
##############################################################

#######################################
##            Libraries              ##
#######################################
#Packages needed to run this script.
library(readxl)

###############################################
##            Prep 2011-2 data              ##
###############################################

# This year of data collection is structured differently than the next two data collection periods, with each question
# In a different file. First, we need to append together the 2011-2012 questions. 

# Setting the directory where all of the 2011-2012 Excel files are stored
# File format and file structure is exactly as when files were downloaded 
# Citation: United States Department of Education. Office for Civil Rights. 2011-12 Civil Rights Data Collection (CRDC).
crdc_files <- "crdc_20112012/sch/CRDC-collected data file for Schools"

# Creating a list with all of the Excel file paths. Full names refers to including the path and not just
# The file name, and recursive means it will go into the folders.
crdc_files_list <- list.files(path = crdc_files, pattern="*.xls", full.names=TRUE, recursive=TRUE, all.files=FALSE)

# Excluding tables that were duplicated in our folders
# These were all manually identified as duplicates
exclude <- c("crdc_20112012/sch/CRDC-collected data file for Schools/Pt 2-Discipline of SwD/36-1 - SwD Corporal punishment.xlsx",
             "crdc_20112012/sch/CRDC-collected data file for Schools/Pt 2-Discipline of SwoD/35-1 - SwoD Corporal punishment.xlsx",
             "crdc_20112012/sch/CRDC-collected data file for Schools/Pt 2-Discipline of SwD/36-9 - SwD School-related arrest.xlsx",
             "crdc_20112012/sch/CRDC-collected data file for Schools/Pt 2-Discipline of SwD/36-8 - SwD Referral to law enforcement.xlsx"
             )
crdc_files_list <- crdc_files_list[!crdc_files_list %in% exclude]

# Merging the files by applying read_excel across the list. Only need sheet 1 for each file
# Also appending the file name to the end of the Incomplete variable since every sheet has that same variable and we need a way to identify it
df.list <- lapply(crdc_files_list, function(x){
  print(x);
  df <- read_excel(x,na="n/a", sheet = 1)
  if ("Incomplete" %in% names(df)){ # Rename incomplete adding dataset name
    df[,paste0("Incomplete_",gsub("//ct-files/securedata/USALEEP/Data/CRDC/crdc_20112012/sch/CRDC-collected data file for Schools/","",x,fixed=TRUE))] <- df$Incomplete
    df$Incomplete <- NULL 
  }
  return(df)
})

# Merge on combokey, which is a unique identifier for schools in the data 
custom_merge <- function(df1,df2){
  # Remove the duplicated identifier columns 
  df2[,c("LEA_STATE","LEAID","LEA_NAME","SCHID","SCH_NAME","JJ")] <- NULL
  return(merge(df1,df2,by="COMBOKEY"))
}

# Left join all spreadsheets together
df <- Reduce(custom_merge, df.list) 


# Adding 2012 to the end of the variable names so that we know what year these are from
names(df) <- paste0(names(df),"_2012")

# Save merged 2011-2012  data as a .csv for use in later scripts
write.csv(df, file = "crdc_20112012/sch/crdc_schmerged_20112012.csv")

###############################################
##            Prep 2013-4 data              ##
###############################################
# Importing 2013-2014 data from Excel file
# Citation: United States Department of Education. Office for Civil Rights. (2017). 2013-14 Civil Rights Data Collection (CRDC). Ann Arbor, MI: Inter-university Consortium for Political and Social Research [distributor]. https://www.datalumos.org/datalumos/project/100445/version/V1/view
crdc2014 <- read.csv("crdc_20132014/sch/CRDC2013_14_SCH.csv", header = TRUE)
names(crdc2014) <- paste0(names(crdc2014),"_2014") # add in year identifier
 

################################################
##            Prep 2016 data                 ##
###############################################

# Importing 2015-2016 data from Excel file
# Citation: United States Department of Education. Office for Civil Rights. (2018). Civil Rights Data Collection (CRDC) for the 2015-16 School Year. Ann Arbor, MI: Inter-university Consortium for Political and Social Research [distributor]. https://doi.org/10.3886/E103004V1 
crdc2016 <- read.csv("crdc_20152016/2015-16-crdc-data/Data Files and Layouts/CRDC 2015-16 School Data.csv", header = TRUE)
names(crdc2016) <- paste0(names(crdc2016),"_2016") # add in year identifier

# Create padding function- SCHID and LEAID are supposed to be left padded with 0s, but excel sometimes removes them
lpad <- function(x,n){
  x <- as.character(x)
  if (nchar(x)<n){
    return(paste0(c(rep("0",n-nchar(x)),x),collapse=""))
  } else {
    return(x)
  }
}

# Recreate combokey from leaid and school id, due to excel sometimes reformatting the original combokey
crdc2016$LEAID_2016_CLEAN <-apply(crdc2016[,"LEAID_2016",drop=F],MARGIN=1,FUN=function(x){lpad(x,7)})
crdc2016$SCHID_2016_CLEAN <-apply(crdc2016[,"SCHID_2016",drop=F],MARGIN=1,FUN=function(x){lpad(x,5)})
crdc2016$COMBOKEY_2016<- paste0(crdc2016$LEAID_2016_CLEAN,crdc2016$SCHID_2016_CLEAN)

################################################
##            Merge All Years                ##
###############################################
# Import 2011-2012 data
# Merge starts with 2012-2014 data prepared in the beggining of this script
crdc2012 <- read.csv("crdc_20112012/sch/crdc_schmerged_20112012.csv", header = TRUE)

# Merge 2012 and 2014 datasets, keeping all rows
crdc20122014 <- merge(x=crdc2012, y=crdc2014, by.x="COMBOKEY_2012", by.y="COMBOKEY_2014", all=T)
names(crdc20122014)[grep("COMBOKEY",names(crdc20122014))] <- "COMBOKEY_20122014" # Rename to make clear the key refers to both years data 

# Merge new 2012-2014 data with 2016 data by first creating new "combokey" varable in both sets
crdc20122014$COMBOKEY <- crdc20122014$COMBOKEY_20122014
crdc2016$COMBOKEY <- crdc2016$COMBOKEY_2016
crdc_all <- merge(x=crdc20122014, y=crdc2016, by="COMBOKEY", all=T)

# Save as rds file due to large file size
saveRDS(crdc_all,"crdc_final_merged.RDS")



