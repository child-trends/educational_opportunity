###########################################################
# Project: USALEEP                                        #
# Purpose: Create the educational opportunity measure     #
# And align highschool data with relevant census tract    #                                                    #
###########################################################


#######################################
##            Libraries             ##
#######################################
library(psych)
library(scales)
library(dplyr)
library(readxl)

# Geospatial statistics
library(rgdal)
library(rgeos)

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

# Divide two vectors, if the denominator is 0, return NA 
divide_no_zero <- function(numerator,denominator){
  denominator[denominator==0] <- NA
  return(numerator/denominator)
}
 
# This is necessary because the base sum(na.rm=T) function returns 0 if you add all NA values, which is not appropriate for this context 
sum_with_na <- function(x){
  if (all(is.na(x))){
    return(NA)
  } else {
    return(sum(x,na.rm=T))
  }
}

# Rescales and takes off the 5th and 95th percentile
rescale_truncate <- function(x){
  # Get 5th and 95th percentile 
  qs <- quantile(x,c(.05,.95),na.rm=T)
  x[x<qs[1]] <- qs[1] #values less than 5th percentile are recoded to fifth percentile
  x[x>qs[2]] <- qs[2] #values more than 95th percentile are recoded to 95th percentile
  return(rescale(x,to=c(0,10)))
}

# Makes numeric variables that are <0 into NA
below_0 <- function(x){
  if(is.numeric(x)){
    x[x<0] <- NA
  }
  return(x)
}

# Recodes to convert categories to numeric values
get_grad_rate <- function(x){
  x <- as.character(x)
  if (grepl("-",x,fixed=T)){
    v1 <- strsplit(x,"-",fixed=T)[[1]][1]
    v2 <- strsplit(x,"-",fixed=T)[[1]][2]
    return(mean(c(as.numeric(v1),as.numeric(v2))))
    
  } else {
    return(gsub("[A-Z]*","",x))
  }
}


##################################
# Recoding variables, by domains #
##################################

# Read in data created by the 2_merge_data.R script 
# This is the complete data 
hs <- readRDS(<<Path to complete data>>)

# Values shared across several domains
# Recode all values <0 to NA since these are the reserve codes used in some years of data
# This only works for numeric variables, but for indicator variables we only look for the "YES" values using the ever_had function above
# Exclude longitude and latitude from this recode
hs <- hs %>% mutate_at(vars(-one_of(c("LAT1516","LON1516"))),below_0)

# Calculate total enrollment for each year
hs$TOT_ENR_2012 <- apply(hs[,c("F_TOT_7_ENROL_2012","M_TOT_7_ENROL_2012")],MARGIN=1,FUN=sum_with_na)
hs$TOT_ENR_2014 <- apply(hs[,c("TOT_ENR_M_2014","TOT_ENR_F_2014")],MARGIN=1,FUN=sum_with_na)
hs$TOT_ENR_2016 <- apply(hs[,c("TOT_ENR_M_2016","TOT_ENR_F_2016")],MARGIN=1,FUN=sum_with_na)
hs$AVG_ENR <- rowMeans(hs[,c("TOT_ENR_2016","TOT_ENR_2014","TOT_ENR_2012")],na.rm=T)


## DOMAIN 1: Access to rigorous academics
#	Indicators: 
# 	a) Any AP courses offered (0 for schools without an AP program); 
#   b) whether or not school has dual enrollment program; 
#   c) number of rigorous math courses


# Indicator 1a: AP classes
# Dichotomous variable of whether any students at this school are enrolled in AP classes

# Recode from count variable to indicator for 2012 
hs$SCH_APENR_2012 <- apply(hs[,c("M_TOT_7_ONE_AP_2012","F_TOT_7_ONE_AP_2012")],MARGIN=1,FUN=sum_with_na)
hs$SCH_APENR_IND_2012 <- ifelse(hs$SCH_APENR_2012>0 ,"YES","NO" )

# Calculate the indicator 
hs$indicator1a <-  apply(hs[,c("SCH_APENR_IND_2012","SCH_APENR_IND_2014","SCH_APENR_IND_2016")],MARGIN=1,FUN=ever_had)
hs$indicator1a_scaled <- ifelse(hs$indicator1a==TRUE,10,0) #scale from 0-10

# Indicator 1b: Dual enrollment
# Dichotomous variable of whether any students at this school are dually enrolled
# 2012 data does not have this variable 
hs$indicator1b <-  apply(hs[,c("SCH_DUAL_IND_2014","SCH_DUAL_IND_2016")],MARGIN=1,FUN=ever_had)
hs$indicator1b_scaled <- ifelse(hs$indicator1b==TRUE,10,0)

# Indicator 1c: Number of Advanced math courses offered
# Mean across all years
# Even though the name in the 2012 data is num_Class_math this is defined as "Number of classes in advanced mathematics" 
# Scale to be per 100 students 
hs$math_class_scaled_2012 <- 100*divide_no_zero(hs$NUM_CLASS_MATH_2012,hs$TOT_ENR_2012)
hs$math_class_scaled_2014 <- 100*divide_no_zero(hs$SCH_MATHCLASSES_ADVM_2014,hs$TOT_ENR_2014)
hs$math_class_scaled_2016 <- 100*divide_no_zero(hs$SCH_MATHCLASSES_ADVM_2016,hs$TOT_ENR_2016)

hs$indicator1c <-  rowMeans(hs[,c("math_class_scaled_2012","math_class_scaled_2014","math_class_scaled_2016")],na.rm=T)

# Continous variables are scaled linearly so thier range can be 0-10
# There is a problem with outliers so we truncate at 5th and 95th percentiles
# In order to run codes below, detached the psych package becasue the two rescale functions fought --
# > detach(package:psych)
hs$indicator1c_scaled  <- rescale_truncate(hs$indicator1c)

## Develop domain
# Run factor analysis to calculate the weights of each item in the scale
# Calculate domain as weighted average of indicators, where weights are factor loadings
scale_scores <- fa(hs[,c("indicator1a_scaled","indicator1b_scaled","indicator1c_scaled")])
hs$domain1 <- apply(hs[,c("indicator1a_scaled","indicator1b_scaled","indicator1c_scaled")],MARGIN=1,FUN=weighted.mean,na.rm=T,w=scale_scores$weights[,1])
hs$DOMAIN1 <- cut(hs$domain1,c(-.1,quantile(hs$domain1,c(.2,.4,.6,.8,1))),right=T,labels = c(1,2,3,4,5)) # start quantiles at -1 to include all 0 values in interval

## DOMAIN 2: Access to supportive learning environments
#	Indicators: 
# 	a) Proportion of students who are not chronically absent
#   b) Number of days lost to out of school suspension (reverse coded so that more days lost corresponds to a negative score)
#   c) Proportion of students who do not experience any out of school suspension

# Indicator 2a: Proportion of students who are NOT chronically absent
# Numerical variable of fraction of students who are NOT chronically absent
# CRDC chronic absenteeism variable refers to the number of students absent for 15 or more school days that academic year
# There is no absenteeism data for 2012 

# Create a variable for total chronic absenteeism for the year by summing gender variables
hs$absenteeism_2014 <- apply(hs[,c("TOT_ABSENT_M_2014","TOT_ABSENT_F_2014")], MARGIN= 1, FUN=sum_with_na)
hs$absenteeism_2016 <- apply(hs[,c("TOT_ABSENT_M_2016","TOT_ABSENT_F_2016")], MARGIN= 1, FUN=sum_with_na)

# Calculate the proportion of Non absent students relative to total enrollment for both years
# Schools reporting 0 enrollment with have a value of NA 
# There are some outliers- they are corrected when the indicator is scaled
hs$not_abs_enr_ratio_2014 <- 1 - divide_no_zero(hs$absenteeism_2014,hs$TOT_ENR_2014)
hs$not_abs_enr_ratio_2016 <- 1 - divide_no_zero(hs$absenteeism_2016,hs$TOT_ENR_2016)

# Calculate the average proportion across the years 2014 and 2016 for each school 
hs$indicator2a <- rowMeans(hs[,c("not_abs_enr_ratio_2014", "not_abs_enr_ratio_2016")], na.rm=TRUE)
# Continous variables are scaled linearly so their range can be 0-10
# There is a problem with outliers so we truncate at 5th and 95th percentiles
hs$indicator2a_scaled  <- rescale_truncate(hs$indicator2a)


# Indicator2b: Number of days absent due to OOS
# Reverse coded at the scaling stage

# Create a variable for total days missed for the year by summing gender variables
# Data available only for the 2015-2016 school year
# Scale to be per 100 students 
hs$days_missed_2016 <- apply(hs[,c("TOT_DAYSMISSED_M_2016","TOT_DAYSMISSED_F_2016")], MARGIN= 1, FUN=sum_with_na)
hs$indicator2b <- 100*divide_no_zero(hs$days_missed_2016,hs$TOT_ENR_2016)


# Continous variables are scaled linearly so thier range can be 0-10
# There is a problem with outliers so we truncate at 5th and 95th percentiles
# Note that this is calculated by subtracting the scaled version from 10 to ensure that higher number of missed days corresponds to a lower score
hs$indicator2b_scaled <- 10 - rescale_truncate(hs$indicator2b)

# Indicator 2c: Proportion of students not experiencing one or more OOS
# Numerical variable of fraction of students who are NOT experiencing OOS

# Create a variable for the total number of OOS for 2012
# This adds both students with disabilities and students without
hs$OOS_2012_WODIS <- apply(hs[,c("M_TOT_7_SINGLE_SUS_NO_DIS_2012","F_TOT_7_SINGLE_SUS_NO_DIS_2012", "M_TOT_7_MULT_SUS_NO_DIS_2012", "F_TOT_7_MULT_SUS_NO_DIS_2012")], MARGIN= 1, FUN=sum_with_na)
hs$OOS_2012_WDIS <- apply(hs[,c("M_504_7_SINGLE_SUS_DIS_2012", "F_504_7_SINGLE_SUS_DIS_2012", "M_504_7_MULT_SUS_DIS_2012", "F_504_7_MULT_SUS_DIS_2012")], MARGIN= 1, FUN=sum_with_na)
hs$OOS_2012 <- apply(hs[,c("OOS_2012_WODIS", "OOS_2012_WDIS")], MARGIN= 1, FUN=sum_with_na)

# Create a variable for the total number of OOS for 2014
# This adds both students with disabilities and students without
hs$OOS_2014_WODIS <- apply(hs[,c("TOT_DISCWODIS_SINGOOS_M_2014","TOT_DISCWODIS_MULTOOS_M_2014", "TOT_DISCWODIS_SINGOOS_F_2014", "TOT_DISCWODIS_MULTOOS_F_2014")], MARGIN= 1, FUN=sum_with_na)
hs$OOS_2014_WDIS <- apply(hs[,c("SCH_DISCWDIS_SINGOOS_504_M_2014", "SCH_DISCWDIS_MULTOOS_504_M_2014", "SCH_DISCWDIS_SINGOOS_504_F_2014", "SCH_DISCWDIS_MULTOOS_504_F_2014")], MARGIN= 1, FUN=sum_with_na)
hs$OOS_2014 <- apply(hs[,c("OOS_2014_WODIS", "OOS_2014_WDIS")], MARGIN= 1, FUN=sum_with_na)

# Create a variable for the total number of OOS for 2016
hs$OOS_2016_WODIS <- apply(hs[,c("TOT_DISCWODIS_SINGOOS_M_2016","TOT_DISCWODIS_MULTOOS_M_2016", "TOT_DISCWODIS_SINGOOS_F_2016", "TOT_DISCWODIS_MULTOOS_F_2016")], MARGIN= 1, FUN=sum_with_na)
hs$OOS_2016_WDIS <- apply(hs[,c("SCH_DISCWDIS_SINGOOS_504_M_2016", "SCH_DISCWDIS_MULTOOS_504_M_2016", "SCH_DISCWDIS_SINGOOS_504_F_2016", "SCH_DISCWDIS_MULTOOS_504_F_2016")], MARGIN= 1, FUN=sum_with_na)
hs$OOS_2016 <- apply(hs[,c("OOS_2016_WODIS", "OOS_2016_WDIS")], MARGIN= 1, FUN=sum_with_na)

# Calculate the proportion of students who DO NOT receive OOS relative to total enrollment for both years
hs$no_OOS_enr_ratio_2012 <- 1 - divide_no_zero(hs$OOS_2012,hs$TOT_ENR_2012)
hs$no_OOS_enr_ratio_2014 <- 1 - divide_no_zero(hs$OOS_2014,hs$TOT_ENR_2014)
hs$no_OOS_enr_ratio_2016 <- 1 - divide_no_zero(hs$OOS_2016,hs$TOT_ENR_2016)

# Calculate the average proportion across the years 2012, 2014, and 2016
hs$indicator2c<- rowMeans(hs[,c("no_OOS_enr_ratio_2012", "no_OOS_enr_ratio_2014", "no_OOS_enr_ratio_2016")], na.rm=TRUE)
# Continous variables are scaled linearly so thier range can be 0-10
# There is a problem with outliers so we truncate at 5th and 95th percentiles
hs$indicator2c_scaled  <- rescale_truncate(hs$indicator2c)

## Develop domain
# Combine the three indicators 
# Combine using factor analysis to calculate the weights of each indicator, and then average
scale_scores_domain2 <- fa(hs[,c("indicator2a_scaled","indicator2b_scaled","indicator2c_scaled")])
hs$domain2 <- apply(hs[,c("indicator2a_scaled","indicator2b_scaled","indicator2c_scaled")],MARGIN=1,FUN=weighted.mean,na.rm=T,w=scale_scores_domain2$weights[,1])

# Cut into 5 equal quartiles 
hs$DOMAIN2 <- cut(hs$domain2,c(-.1,quantile(hs$domain2,c(.2,.4,.6,.8,1))),right=T,labels = c(1,2,3,4,5)) # start quantiles at -1 to include all 0 values in interval

## DOMAIN 3: Access to appropriate nonacademic supports
#	Indicators: 
#  a) Number of FTE school counselors per 100 students
#  b)	Number of FTE nurses per 100 students
#  c) Number of FTE psychologists per 100 students
#  d)	Number of FTE social workers per 100 students

# Indicator 3a: Number of FTE school counselors per 100 students
# Numerical variable of FTE school counselors for each 100 students enrolled in a school

# Divide the number of FTE counselors at each school by the total enrollment for each year multiplied by 100
hs$ratio_counselors_2012_per100 <- divide_no_zero(100 * hs$COUNSEL_2012, hs$TOT_ENR_2012)
hs$ratio_counselors_2014_per100 <- divide_no_zero(100 * hs$SCH_FTECOUNSELORS_2014, hs$TOT_ENR_2014)
hs$ratio_counselors_2016_per100 <- divide_no_zero(100 * hs$SCH_FTECOUNSELORS_2016, hs$TOT_ENR_2016)

# Calculate the average across 2012, 2014, and 2016 for each school
hs$indicator3a <- rowMeans(hs[,c("ratio_counselors_2012_per100", "ratio_counselors_2014_per100", "ratio_counselors_2016_per100")], na.rm=TRUE)
# Continous variables are scaled linearly so thier range can be 0-10
# There is a problem with outliers so we truncate at 5th and 95th percentiles
hs$indicator3a_scaled  <- rescale_truncate(hs$indicator3a)

# Indicator 3b: Number of FTE nurses per 100 students
# Numerical variable of FTE nurses for each 100 students enrolled in a school
# Data available only for the 15-16 school year

# Divide the number of FTE nurses at each school by the total enrollment and multiply by 100
hs$indicator3b <- divide_no_zero(100 * hs$SCH_FTESERVICES_NUR_2016, hs$TOT_ENR_2016)
# Continous variables are scaled linearly so thier range can be 0-10
# There is a problem with outliers so we truncate at 5th and 95th percentile
hs$indicator3b_scaled  <- rescale_truncate(hs$indicator3b)

# Indicator 3c: Number of FTE pscyhologists  per 100 students
# Numerical variable of FTE psychologists for each 100 students enrolled in a school
# Data available only for the 15-16 school year

# Divide the number of FTE psychologists at each school by the total enrollment and multiply by 100
hs$indicator3c <- divide_no_zero(100 * hs$SCH_FTESERVICES_PSY_2016, hs$TOT_ENR_2016)
# Continous variables are scaled linearly so their range can be 0-10
# There is a problem with outliers so we truncate at 5th and 95th percentiles
hs$indicator3c_scaled  <- rescale_truncate(hs$indicator3c)

# Indicator 3d: Number of FTE social workers per 100 students
# Numerical variable of FTE social workers for each 100 students enrolled in a school
# Data available only for the 15-16 school year

# Divide the number of FTE social workers at each school by the total enrollment and multiply by 100
hs$indicator3d <- divide_no_zero(100 * hs$SCH_FTESERVICES_SOC_2016, hs$TOT_ENR_2016)
hs$indicator3d_scaled  <- rescale_truncate(hs$indicator3d)

## Develop domain
# Combine the three indicators 
# Use factor analysis to calculate weights of each item in final domain
scale_scores_domain3 <- fa(hs[,c("indicator3a_scaled","indicator3b_scaled","indicator3c_scaled","indicator3d_scaled")])
hs$domain3 <- apply(hs[,c("indicator3a_scaled","indicator3b_scaled","indicator3c_scaled","indicator3d_scaled")],MARGIN=1,FUN=weighted.mean,na.rm=T,w=scale_scores_domain3$weights[,1])

# Cut into 5 equal quartiles 
hs$DOMAIN3 <- cut(hs$domain3,c(-.1,quantile(hs$domain3,c(.2,.4,.6,.8,1))),right=T,labels = c(1,2,3,4,5)) # start quantiles at -1 to include all 0 values in interval

# DOMAIN 4: Access to effective teaching
#	Indicators: 
#   a) Proportion of teachers with more than 2 years of experience

# Indicator 4a: Teachers with >2 years of experience
# Numerical variable of proportion of teachers with more than 2 years teaching experience

# If total  FTE teachers are <1 code to one 
hs$SCH_FTETEACH_TOT_2014[hs$SCH_FTETEACH_TOT_2014<1] <- 1
hs$SCH_FTETEACH_TOT_2016[hs$SCH_FTETEACH_TOT_2016<1] <- 1

# Add together first year and second year
hs$SCH_FTETEACH_FSY_2014 <- apply(hs[,c("SCH_FTETEACH_FY_2014","SCH_FTETEACH_SY_2014")],MARGIN =1,FUN = sum_with_na)
hs$SCH_FTETEACH_FSY_2016 <- apply(hs[,c("SCH_FTETEACH_FY_2016","SCH_FTETEACH_SY_2016")],MARGIN =1,FUN = sum_with_na)

# Change values of teachers that were first and second year that are higher than FTE teachers to NA
hs$SCH_FTETEACH_FSY_2014[hs$SCH_FTETEACH_FSY_2014>hs$SCH_FTETEACH_TOT_2014] <- NA
hs$SCH_FTETEACH_FSY_2016[hs$SCH_FTETEACH_FSY_2016>hs$SCH_FTETEACH_TOT_2016] <- NA

# Calculate percentage of total teachers
hs$PRO_NON_FSY_2014 <- 1 - divide_no_zero(hs$SCH_FTETEACH_FSY_2014, hs$SCH_FTETEACH_TOT_2014)
hs$PRO_NON_FSY_2016 <- 1- divide_no_zero(hs$SCH_FTETEACH_FSY_2016, hs$SCH_FTETEACH_TOT_2016)

# Calculate indicator
hs$indicator4a <-  rowMeans(hs[,c("PRO_NON_FSY_2014","PRO_NON_FSY_2016")],na.rm=TRUE)

# Continous variables are scaled linearly so thier range can be 0-10
# There is a problem with outliers so we truncate at 5th and 95th percentiles
hs$indicator4a_scaled  <- rescale_truncate(hs$indicator4a)

## Develop domain
# Cut into 5 equal quintiles 
# No factor analysis is needed for this domain because there is only one item
hs$domain4 <- hs$indicator4a_scaled
hs$DOMAIN4 <- cut(hs$domain4,c(-.1,quantile(hs$domain4,c(.2,.4,.6,.8,1), na.rm=T)),right=T,labels = c(1,2,3,4,5)) # start quantiles at -1 to include all 0 values in interval


##################################
# Create overall indicator       #
##################################
hs$EDUCATIONAL_OPP <- rowMeans(hs[,c("domain1","domain2","domain3","domain4")],na.rm=TRUE)
hs$EDUCATIONAL_OPP_CATEGORY <- cut(hs$EDUCATIONAL_OPP,c(-.1,quantile(hs$EDUCATIONAL_OPP,c(.2,.4,.6,.8,1), na.rm=T)),right=T,labels = c(1,2,3,4,5)) # start quantiles at -1 to include all 0 values in interval

######################################################
# Create School characteristic variables             #
######################################################

## Calculate summary school characteristic variables 

# Special Education
hs$SCH_STATUS_SPED_2012 <- ifelse(hs$SP_ED_2012==1,"YES","NO")
hs$SPED<-  apply(hs[,c("SCH_STATUS_SPED_2012" ,"SCH_STATUS_SPED_2014","SCH_STATUS_SPED_2016")],MARGIN=1,FUN=ever_had)

# Magnet School
hs$SCH_STATUS_MAGNET_2012 <- ifelse(hs$MG_SCH_2012==1,"YES","NO") # this is more restrictive (ie only fully magnet schoools) than later definitions
hs$MAGNET <-  apply(hs[,c("SCH_STATUS_MAGNET_2012","SCH_STATUS_MAGNET_2014","SCH_STATUS_MAGNET_2016")],MARGIN=1,FUN=ever_had)

# Charter School
hs$SCH_STATUS_CHARTER_2012 <- ifelse(hs$CHARTER_SCH_2012==1,"YES","NO") # this is more restrictive (ie only fully magnet schoools) than later definitions
hs$CHARTER <-  apply(hs[,c("SCH_STATUS_CHARTER_2012","SCH_STATUS_CHARTER_2014","SCH_STATUS_CHARTER_2016")],MARGIN=1,FUN=ever_had)

# Alternative schoool
hs$ALTERNATIVE <-  apply(hs[,c("SCH_STATUS_ALT_2014","SCH_STATUS_ALT_2016")],MARGIN=1,FUN=ever_had)

# Juvenile Justice 
hs$JJ_2012 <- ifelse(!is.na(hs$JJ_2012),"YES","NO")
hs$JJ <-  apply(hs[,c("JJ_2012","JJ_2014","JJ_2016")],MARGIN=1,FUN=ever_had)

## Calculate latest school name 
hs$SCH_NAME <- as.character(hs$SCH_NAME_2016)
hs$SCH_NAME <- ifelse(is.na(hs$SCH_NAME),as.character(hs$SCH_NAME_2014),hs$SCH_NAME) # if 2016 is missing fill with 2014
hs$SCH_NAME <- ifelse(is.na(hs$SCH_NAME),as.character(hs$SCH_NAME_2012),hs$SCH_NAME) # if 2014 and 2016 is missing fill with 2012

# Virtual schools
# this is a rough calcuation based on having virtual, online or correspondence in the name
hs$virtual <- grepl("virtual|online|correspondence",tolower(hs$SCH_NAME))

## Rename geography
hs$LAT <- hs$LAT1516
hs$LON <- hs$LON1516

# Rename code graduation rates and multiply by 100 to go from rate to percentage
# These are numbers sometimes but also have GE (greater than or equal) or LE (less than or equal to). 
# Values that are GE or LE are assigned to that number 
# Data presented as a range are given the average 
# Quite a lot of values in the original data are NA due to imperfect matching
hs$GRAD_RATE_1112 <- as.numeric(unlist(lapply(hs$ALL_RATE_1112,FUN=get_grad_rate)))
hs$GRAD_RATE_1314 <- as.numeric(unlist(lapply(hs$ALL_RATE_1314,FUN=get_grad_rate)))
hs$GRAD_RATE_1516 <- as.numeric(unlist(lapply(hs$ALL_RATE_1516,FUN=get_grad_rate)))

# Average across three years of data
hs$GRAD_RATE_AVG <-  rowMeans(hs[,c("GRAD_RATE_1112","GRAD_RATE_1314","GRAD_RATE_1516")],na.rm=TRUE)

# Add number of schools in census tract
hs <- hs %>% group_by(Tract.ID) %>% mutate(n_schools_in_tract =n())

##################################
# Identify variables to keep     #
##################################

# Variables to keep 
keep <- c("COMBOKEY","Tract.ID","life_expectancy_at_start.15-24","life_expectancy_at_start_se.15-24","LAT","LON","COMBOKEY","SPED","MAGNET","CHARTER","ALTERNATIVE","SCH_NAME",
          "indicator1a","indicator1b","indicator1c","DOMAIN1","domain1","indicator1a_scaled","indicator1b_scaled","indicator1c_scaled",
          "indicator2a","indicator2b","indicator2c","domain2","DOMAIN2","indicator2a_scaled","indicator2b_scaled","indicator2c_scaled",
          "indicator3a","indicator3b","indicator3c","indicator3d","DOMAIN3","domain3","indicator3a_scaled","indicator3b_scaled","indicator3c_scaled","indicator3d_scaled",
          "indicator4a","DOMAIN4","domain4","indicator4a_scaled",
          "EDUCATIONAL_OPP","EDUCATIONAL_OPP_CATEGORY","AVG_ENR",
          "Percent_Under_Twice_Poverty_Level","Percent_Under_Poverty_Level","Majority_Race","Percent_Hispanic","Percent_White","Percent_Black","Percent_American_Indian","Asian","Pacific_Islander","Other","Two_Or_More",
          "GRAD_RATE_1112","GRAD_RATE_1314","GRAD_RATE_1516","n_schools_in_tract","life_expectancy_at_start.15-24_plus_15")

# Filter to non-Juvenile Justice and non-Virtual schools because of geospatial matching issues
# Add 15 years to life expectancy at age 15 to get total life expectancy
hs$`life_expectancy_at_start.15-24_plus_15` <- hs$`life_expectancy_at_start.15-24`+15
hs_physical <- hs %>% subset((JJ==FALSE) & (virtual==FALSE))
# this is the final data on physical schools used for mapping
write.csv(hs[,keep],"physical_school_data.csv")

#######################################
#  Match School data to Census data   #
#######################################

# This is the base Census tract and life expectancy data 
# All census tracts from the LEEP Data 
# created in script 2_merge_data.R
LEEP <- read.csv("USALEEP_AND_ACS.csv")
LEEP$TRACT <- apply(LEEP[,"Tract.ID",drop=F],MARGIN=1,FUN=function(x){lpad(x,11)})

# The NCES crosswalk will be used to identify what school district a census tract matches with
# This was downloaded from https://nces.ed.gov/programs/edge/Geographic/RelationshipFiles on October 10,2019
nces_crosswalk <- read_excel("grf15_lea_tract.xlsx")

# Prep LEA variable for HS data set
hs$COMBOKEY<- apply(hs[,"COMBOKEY",drop=F],MARGIN=1,FUN=function(x){lpad(x,12)})
hs$LEAID <- substr(hs$COMBOKEY,0,7) #LEAID is first 7 digits of combokey

# Read in spatial data set for census tracts
# This is a shape file of all census tracts in the US 
census_geo <- readOGR( "Census tracts", "us_census_tract_2015")

# Create a spatial points data set of the school data 
schs_sdf <- SpatialPointsDataFrame(hs[,c("LON","LAT")], # the columns giving x and y
                                   hs )  #the whole data frame to be converted

# Set the projection of the SpatialPointsDataFrame using the projection of the shapefile
proj4string(schs_sdf) <- CRS("+proj=longlat")


# Create a spatial points data set without JJ or virtual schools
hs_restricted <- hs %>% subset((JJ==F) & (virtual ==FALSE))

schs_sdf_restricted <- SpatialPointsDataFrame(hs_restricted[,c("LON","LAT")], # the columns giving x and y
                                   hs_restricted ) 
proj4string(schs_sdf_restricted) <- CRS("+proj=longlat")

# Project both to albers equal area 
# This is probably not stricly necessary given the short distances we are working with, but is still good practice 
# Projection string comes from https://spatialreference.org/ref/esri/usa-contiguous-albers-equal-area-conic/proj4js/
aea.proj <- "+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-110
+x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m"

# Project the census tract outlines and school locations
schs_sdf_restricted <- spTransform(schs_sdf_restricted, CRS(aea.proj))
census_geo <- spTransform(census_geo, CRS(aea.proj))


# Iterate through each census tract
match_schools <- function(TRACT,data,nces_crosswalk,schs_sdf){
  
  # First handle those census tracts with a school or schools in them 
  if (TRACT %in% data$Tract.ID){
    school <- data[data$Tract.ID == TRACT & !is.na(data$Tract.ID),]

    results <- school %>% 
      ungroup() %>%
      select(c("COMBOKEY")) 
    
    # All data for  schools in this data set are now associated with the given tract 
    results$Tract.ID <- TRACT 

  } else { # Handle tracts that dont have a school in them
    # Limit census geographic data set to just the relevant track 
    tract_geo <- census_geo[census_geo$GEOID==TRACT,]
    
    # Look up what school district the census tract is in
    school_districts <- nces_crosswalk[nces_crosswalk$TRACT==TRACT,"LEAID"]
    
    # Filter points data frame to just schools in those school districts 
    matching_schools <- schs_sdf[schs_sdf$LEAID %in% school_districts,]
    
    # If there are not matching_schools return NULL
    if (nrow(matching_schools)==0){
      return(NULL)
    }
    
    # Now find the school closest to the census tract
    # This is the minimum distance between the school and the census tract border
    distances <- apply(gDistance(matching_schools, tract_geo,byid=TRUE),2,min)
    
    # This gets all schools that the closest to tract border (may be more than one school if two school share a location)
    closest_schools<- matching_schools[which(distances==min(distances,na.rm=T)),]$COMBOKEY
 
    results <- data %>% 
      filter(COMBOKEY %in% closest_schools) %>% 
      ungroup() %>%
      select(c("COMBOKEY")) 
    
    # Add on real tract variable 
    results$Tract.ID <- TRACT 
  }

  return(results)
}

results_restrictive <-  lapply(LEEP$TRACT,match_schools,data=hs_restricted,nces_crosswalk=nces_crosswalk,schs_sdf=schs_sdf_restricted)

final <- Reduce(rbind,results_restrictive)

# Merge in school data taking only relevant numeric variables 
relevant_vars <- c("indicator1a","indicator1b","indicator1c","domain1","indicator1a_scaled","indicator1b_scaled","indicator1c_scaled",
                  "indicator2a","indicator2b","indicator2c","domain2","indicator2a_scaled","indicator2b_scaled","indicator2c_scaled",
                  "indicator3a","indicator3b","indicator3c","indicator3d","domain3","indicator3a_scaled","indicator3b_scaled","indicator3c_scaled","indicator3d_scaled",
                  "indicator4a","domain4","indicator4a_scaled",
                  "EDUCATIONAL_OPP",
                  "GRAD_RATE_1112","GRAD_RATE_1314","GRAD_RATE_1516","AVG_ENR")

hs$Tract.ID <- NULL # Remove redundant tract column from school data for clarity
final_w_school <- merge(final,hs,by="COMBOKEY",all.x=T,all.y=F)

# Group by tract to handle cases with >1 school in a tract or close to a tract
# if more than on school matches to a tract, the value of the indicators is the weighted average 
# weighted by average enrollment
final_w_school_grouped <- final_w_school %>% 
  select(c("Tract.ID",relevant_vars)) %>%
                          group_by(Tract.ID) %>% 
                             summarise_all(funs(weighted.mean(.,AVG_ENR,na.rm=T)))

# Recacluate opportunity category based on quantiles of combined scores 
final_w_school_grouped$EDUCATIONAL_OPP_CATEGORY <- cut(final_w_school_grouped$EDUCATIONAL_OPP,c(-.1,quantile(final_w_school_grouped$EDUCATIONAL_OPP,c(.2,.4,.6,.8,1), na.rm=T)),right=T,labels = c(1,2,3,4,5)) # start quantiles at -1 to include all 0 values in interval

# Merge in Cenus data with ACS information
final_w_school_and_census <- merge(final_w_school_grouped,LEEP,by.x="Tract.ID",by.y="TRACT",all=T)

# Add more 15 to life expectancy 
final_w_school_and_census$life_expectancy_at_start.15.24_plus_15 <- final_w_school_and_census_restrictive$life_expectancy_at_start.15.24 +15

# This is the full final data 
write.csv(final_w_school_and_census,"final_data.csv")