##################################################################
# Project: USALEEP                                               #
# Purpose: Geographically match census tracts with high schools  #
##################################################################

#######################################
##            Libraries              ##
#######################################
#Packages needed to run this script.

# Geospatial statistics
library(tigris)
library(raster)
library(rgdal)  
library(sp)
library(maptools)

# Vizualization
library(leaflet)

# Reading excel files 
library(readxl)

# Data manipulation
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


#############################################
##            Data Collection              ##
#############################################

# This is the tigerlines shape file for census tracts in 2015 
# downloaded with the rpackage tigris in September 2019

# Get all data from states and DC
states <- c("AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA", 
            "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA", 
            "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", 
            "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX", 
            "UT", "VT", "VA", "WA", "WV", "WI", "WY","DC")
shape <- list()

# Download tract boundaries for 2015, with cb=TRUE to get 1:500k resolution
for (state in states){
  shape[state] <- tracts(state,year=2015,cb = TRUE)
}

# Merge together all shapes 
final <- Reduce(bind,shape)

# Save to shape file
# Citation: Kyle Walker (2019). tigris: Load Census TIGER/Line Shapefiles. R
# package version 0.8.2. https://CRAN.R-project.org/package=tigris
writeOGR(final, "Census tracts", "us_census_tract_2015", driver="ESRI Shapefile")


############################################################
##            Match CCD data to census tracts             ##
############################################################

# read in shape file of census tracts
final <- readOGR( "Census tracts", "us_census_tract_2015")

# Load in the lat and long of schools from CCD
schs <- read_excel("CCD Geographic Data/EDGE_GEOCODE_PUBLICSCH_1516/EDGE_GEOCODE_PUBLICSCH_1516.xlsx")

# Convert points to spatial data frame 
# Note that no projection is used yet
schs_sdf <- SpatialPointsDataFrame(schs[,c("LON1516","LAT1516")], # the columns giving x and y
                                   schs )  #the whole data frame to be converted

# Set the projection of the SpatialPointsDataFrame using the projection of the shapefile
proj4string(schs_sdf) <- CRS("+proj=longlat")

# Convert to same projection as polygon file
schs_sdf <- spTransform(schs_sdf, proj4string(final))

# Identify which schools are in each census tract 
overlap <- over(schs_sdf, final)
overlap <- cbind(overlap,data.frame(schs_sdf)) #augment with data

# Read in HS data created in the 2_merge_data.R script
hs <- readRDS("ccd_crdc_usaleep_highschool.RDS")

# Read the USALEEP data and prepare 
usaleep <- read.csv("USALEEP/US_B.CSV")
# Rename life expectancy probability vars
names(usaleep)[c(6:length(names(usaleep)))] <- c("prob_dying_in_age_group",
                                                 "n_surive_to_age",
                                                 "n_die_in_age_group",
                                                 'person_years_lived_in_age_group',
                                                 "person_years_lived_past_start",
                                                 "life_expectancy_at_start",
                                                 "prob_dying_in_age_group_se",
                                                 "life_expectancy_at_start_se")

# Pivot so one row represents each Tract
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

census <- hs %>% select(c("Tract.ID",numeric_vars)) %>% 
  group_by(Tract.ID) %>% 
  summarise_all(funs(mean),na.rm=T) 

# Save file
write.csv(census,"census_data.csv")

