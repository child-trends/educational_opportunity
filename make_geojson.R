library(tidyverse)
library(sf)

#download shapefiles and convert to geojson

get_shp <- function(fips, dir, year=2015, geo="place", res="500k"){
  cat("\n++++++++++\nGetting shapefile and converting to geojson: ")
  cat(fips)
  cat("\n")
  
  #file name/location of place shapefile archive
  f <- paste("cb", year, fips, geo, res, sep="_")
  fzip <- paste0(f, ".zip")
  uri <- paste0("https://www2.census.gov/geo/tiger/GENZ", year, "/shp/", fzip)
  
  #local file paths
  zipfile <- file.path(dir, "zip", fzip)
  shpdir <- file.path(dir, "shp", f)
  
  download.file(uri, destfile=zipfile, method="wget", quiet=TRUE)
  unzip(zipfile, exdir=shpdir)
  
  shp <- st_read(shpdir, f, stringsAsFactors=FALSE)
  
  st_write(shp, file.path(dir,"geojson", paste0(fips,".json")), driver="GeoJSON", delete_dsn=TRUE)
}

# dir is a path to a directory that should be structured as follows:
# dir/
#   geojson/
#   shp/
#   zip/

get_all_shp <- function(dir){
  #data frame of all states to loop through
  states <- tibble(
    fips = c("01", "02", "04", "05", "06", "08", "09", "10", "11", "12", 
             "13", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", 
             "25", "26", "27", "28", "29", "30", "31", "32", "33", "34", "35", 
             "36", "37", "38", "39", "40", "41", "42", "44", "45", "46", "47", 
             "48", "49", "50", "51", "53", "54", "55", "56"),
    
    usps = c("AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "DC", "FL", 
             "GA", "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", 
             "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", 
             "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", 
             "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY")
  )
  
  for(i in 1:nrow(states)){
    get_shp(states$fips[i], dir=dir)
  }
}

#ex: get_all_shp("/home/.../build/")

