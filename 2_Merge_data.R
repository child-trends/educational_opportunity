############################################################
# Project: USALEEP                                         #
# Purpose: Merge CRDC,CCD and life expectancy data sources #
############################################################

#######################################
##            Libraries              ##
#######################################
#Packages needed to run this script.
library(dplyr)


##################################
## Helper functions             ##
##################################

# This is necessary because school IDs should be left-padded with 0s, but excel sometimes removes them
lpad <- function(x,n){
  if (!is.na(x)){
    x <- as.character(x)
    if (nchar(x)<n){
      return(paste0(c(rep("0",n-nchar(x)),x),collapse=""))
    } else {
      return(x)
    }} else {
      return(x)
    }
}

# This is necessary to avoid erroneous 0s due to NAs
ever_had <- function(x){
  if (all(is.na(x))){
    return(FALSE)
  } else if (any(tolower(as.character(x))=="yes",na.rm=T)){
    return(TRUE)
  } else {
    return(FALSE)
  }
}

# This is necessary because the base sum(na.rm=T) function returns 0 if you add all NA values, which is not appropriate for this context 
sum_with_na <- function(x){
  if (all(is.na(x))){
    return(NA)
  } else {
    return(sum(x,na.rm=T))
  }
}


#############################################
##            Data Collection              ##
#############################################

# Import the CRDC RDS
# this data includes CRDC data from 2011-12,2013-14 and 2015-16 processed by the script 1_merge CRDC
crdc<-readRDS(file = "crdc_final_merged.RDS")
crdc$IN_CRDC <- TRUE

# Merge the CCD Geography and add indicator variable for later review
# Citation: Education Demographics and Geographic Estimates.National Center for Education Statistics (2019).Retrieved December 9, 2019 from: https://nces.ed.gov/programs/edge/Geographic/SchoolLocations
ccd<-read.csv(file = "CCD Geographic Data/ccd_with_census_tract.csv")
ccd$IN_CCD <- TRUE

# Pad tract to be 11 digits
ccd$Tract.ID  <-apply(ccd[,"GEOID",drop=F],MARGIN=1,FUN=function(x){lpad(x,11)})

# Left pad combokey, due to excel sometimes reformatting the original combokey
ccd$COMBOKEY  <-apply(ccd[,"NCESSCH",drop=F],MARGIN=1,FUN=function(x){lpad(x,12)})

# Merge data- only schools in CCD are kept because it's our only source of geo information
#and also only those in CRDC becasue it's our key source of variables.
merge1 <- merge(ccd,crdc,by="COMBOKEY",all.x=F,all.y=F)

# Merge the USALEEP data
# Citation: National Center for Health Statistics. (2018). U.S. Small-area Life Expectancy Estimates Project - USALEEP. Retrieved December 9, 2019 from: https://www.cdc.gov/nchs/nvss/usaleep/usaleep.html
# Data format and file structures are exactly as on download from USALEEP website
usaleep <- read.csv("USALEEP/US_B.CSV")

# Rename life expectancy probability variables
names(usaleep)[c(6:length(names(usaleep)))] <- c("prob_dying_in_age_group",
                                                 "n_surive_to_age",
                                                 "n_die_in_age_group",
                                                 'person_years_lived_in_age_group',
                                                 "person_years_lived_past_start",
                                                 "life_expectancy_at_start",
                                                 "prob_dying_in_age_group_se",
                                                 "life_expectancy_at_start_se")

# Pivot so one row represents each tract
usaleep_wide <- reshape(usaleep[,c("Tract.ID","Age.Group","prob_dying_in_age_group",
                                   "n_surive_to_age",
                                   "n_die_in_age_group",
                                   'person_years_lived_in_age_group',
                                   "person_years_lived_past_start",
                                   "life_expectancy_at_start",
                                   "prob_dying_in_age_group_se",
                                   "life_expectancy_at_start_se")],
                                   idvar = "Tract.ID",
                                   timevar = "Age.Group",
                                   direction = "wide")

# Pad tract to be 11 digits
usaleep_wide$Tract.ID  <-apply(usaleep_wide[,"Tract.ID",drop=F],MARGIN=1,FUN=function(x){lpad(x,11)})

# Make geo file for mapping 
write.csv(usaleep_wide[,c("Tract.ID","life_expectancy_at_start.15-24")],"life_expectancy.csv")

# Merge data- only schools in CCD are kept because its our only source of geo information
# Keep schools that dont match to USALEEP in case of later need
merge2 <- merge(merge1,usaleep_wide,by="Tract.ID",all.x=T,all.y=F)

# Merge the 2011-2015 NHGIS data
# Citation: Steven Manson, Jonathan Schroeder, David Van Riper, and Steven Ruggles. IPUMS National Historical Geographic Information System: Version 14.0 [Database]. Minneapolis, MN: IPUMS. 2019. http://doi.org/10.18128/D050.V14.0
nhgis <- read.csv("nhgis0001_csv/nhgis0001_ds215_20155_2015_tract.csv")

# We construct our own census tract id with State (2 digts) + County(3 digit) + Tract (6 digits)
nhgis$STATEFIPS <- apply(nhgis[,"STATEA",drop=F],MARGIN=1,FUN=function(x){lpad(x,2)})
nhgis$COUNTYFIPS <- apply(nhgis[,"COUNTYA",drop=F],MARGIN=1,FUN=function(x){lpad(x,3)})
nhgis$TRACTFIPS <- apply(nhgis[,"TRACTA",drop=F],MARGIN=1,FUN=function(x){lpad(x,6)})
nhgis$Tract.ID <- apply(nhgis[,c("STATEFIPS","COUNTYFIPS","TRACTFIPS")],MARGIN=1,FUN=paste0,collapse="")

# Recode Race 
# ADKXE001:    Total population
# ADKXE002:    White alone
# ADKXE003:    Black or African American alone
# ADKXE004:    American Indian and Alaska Native alone
# ADKXE005:    Asian alone
# ADKXE006:    Native Hawaiian and Other Pacific Islander alone
# ADKXE007:    Some other race alone
# ADKXE008:    Two or more races
nhgis$Percent_White <- 100 * nhgis$ADKXE002 / nhgis$ADKXE001
nhgis$Percent_Black <- 100 * nhgis$ADKXE003 / nhgis$ADKXE001
nhgis$Percent_American_Indian <- 100 * nhgis$ADKXE004 / nhgis$ADKXE001
nhgis$Percent_Asian <- 100 * nhgis$ADKXE005 / nhgis$ADKXE001
nhgis$Percent_Pacific_Islander <- 100 * nhgis$ADKXE006 / nhgis$ADKXE001
nhgis$Percent_Other <- 100 * nhgis$ADKXE007 / nhgis$ADKXE001
nhgis$Percent_Two_Or_More <- 100 * nhgis$ADKXE008 / nhgis$ADKXE001

# Recode Ethnicity 
# ADK5E012:    Hispanic or Latino
nhgis$Percent_Hispanic <- 100*nhgis$ADK5E012 / nhgis$ADKXE001

# Recode Poverty
# Ratio of Income to Poverty Level in the Past 12 Months
# Universe:    Population for whom poverty status is determined
# Source code: C17002
# NHGIS code:  ADNE
# ADNEE001:    Total
# ADNEE002:    Under .50
# ADNEE003:    .50 to .99
# ADNEE004:    1.00 to 1.24
# ADNEE005:    1.25 to 1.49
# ADNEE006:    1.50 to 1.84
# ADNEE007:    1.85 to 1.99
# ADNEE008:    2.00 and over
# Sum the percent under .5 and .5 to .99 of povertly level 
nhgis$Percent_Under_Poverty_Level <- 100* apply(nhgis[,c("ADNEE002","ADNEE003")],MARGIN=1,FUN=sum_with_na)/nhgis$ADNEE001
# Sum all under twice poverty level 
nhgis$Percent_Under_Twice_Poverty_Level <- 100* apply(nhgis[,c("ADNEE002","ADNEE003","ADNEE004","ADNEE005","ADNEE006","ADNEE007")],MARGIN=1,FUN=sum_with_na)/nhgis$ADNEE001

# Merge in census data 
merge3 <- merge(merge2,nhgis[,c("Tract.ID","Percent_Under_Twice_Poverty_Level","Percent_Under_Poverty_Level","Percent_Hispanic","Percent_White","Percent_Black","Percent_American_Indian","Asian","Pacific_Islander","Other","Two_Or_More")],by="Tract.ID",all.x=T,all.y=F)

# Make seperate merged geography file for use in mappnig
geo_file <- merge(usaleep_wide[,c("Tract.ID","life_expectancy_at_start.15-24","life_expectancy_at_start_se.15-24")],nhgis[,c("Tract.ID","Percent_Under_Twice_Poverty_Level","Percent_Under_Poverty_Level","Majority_Race","Percent_Hispanic","Percent_White","Percent_Black","Percent_American_Indian","Asian","Pacific_Islander","Other","Two_Or_More")],by="Tract.ID",all.x=T,all.y=F)
write.csv(geo_file, "USALEEP_AND_ACS.csv")

###################################
# Defining population of interest #
###################################

# Keep only schools that had enrollment for a G9-12 (grade 9-12, i.e., high shcool) student any time in all 3 data collections
# First get variable names that represent enrollment in G9-12
# 2012 has variable as number enrolled
hs_grades_2012 <- names(merge3)[grep("^G9_|^G10_|^G11_|^G12",names(merge3))]
merge3$HighSchool_2012 <- apply(merge3[,hs_grades_2012],MARGIN=1,FUN=function(x){return(sum(x)>0)})

# Post-2012 have indicator Yes vs No variable
hs_grades <- names(merge3)[grep("^SCH_GRADE_G09_|^SCH_GRADE_G10_|^SCH_GRADE_G11_|^SCH_GRADE_G12_",names(merge3))]
merge3$HighSchool_20142016<- apply(merge3[,hs_grades],MARGIN=1,FUN=function(x){return(sum(x=="Yes")>0)})

# School is a high school if it has ever had grades 9-12 students
merge3$is_hs <-  apply(merge3[,c("HighSchool_20142016","HighSchool_2012")],MARGIN=1,FUN=function(x){any(x)==T})

# Filter only to high schools 
hs <- merge3[merge3$is_hs==T & !is.na(merge3$is_hs),]

# Read in graduation rate data for all 3 sets of data
# Citation: US Department of Education. (2019). EDFacts Data Files. Retrieved December 9, 2019 from: https://www2.ed.gov/about/inits/ed/edfacts/data-files/index.html
grad_rates_2012 <- read.csv("EdFacts Graduation Rates/acgr-sch-sy2011-12.csv")
grad_rates_2014 <- read.csv("EdFacts Graduation Rates/acgr-sch-sy2013-14.csv")
grad_rates_2016 <- read.csv("EdFacts Graduation Rates/acgr-sch-sy2015-16.csv")

# Match on NCESSCH ID ater first padding to be 12 digits 
grad_rates_2012$COMBOKEY<-apply(grad_rates_2012[,"NCESSCH",drop=F],MARGIN=1,FUN=function(x){lpad(x,12)})
grad_rates_2014$COMBOKEY<-apply(grad_rates_2014[,"NCESSCH",drop=F],MARGIN=1,FUN=function(x){lpad(x,12)})
grad_rates_2016$COMBOKEY<-apply(grad_rates_2016[,"NCESSCH",drop=F],MARGIN=1,FUN=function(x){lpad(x,12)})

# Merge the graduation rate data with the larger dataset
hs <- merge(hs, grad_rates_2012[,c("COMBOKEY","ALL_RATE_1112")],by="COMBOKEY",all.x=T,all.y=F)
hs <- merge(hs, grad_rates_2014[,c("COMBOKEY","ALL_RATE_1314")],by="COMBOKEY",all.x=T,all.y=F)
hs <- merge(hs, grad_rates_2016[,c("COMBOKEY","ALL_RATE_1516")],by="COMBOKEY",all.x=T,all.y=F)

# save final results for late use. RDS due to size 
saveRDS(hs,"ccd_crdc_usaleep_highschool.RDS")

