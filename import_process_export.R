inputdir <- "/path/to/input/data/"
outputdir <- "/path/to/output/data"

library(dplyr)
library(readr)
library(jsonlite)
library(readxl)
library(tidyr)

#physical_school_data_nov_18.csv
#This is the school data set. About 24k records (schools), and the census tract information that is associated with that school.

#final_data_11_18_physical_schools.csv
#This is the census tract level data (ie the main data on which the report is based). There are about 65k census tracts 
#(ie all tracts that USALEEP made life expectancy estimates for). Of these, about 51k have school information associated with them.

############# DISTRICT NAMES ################
lea <- read_csv(paste0(inputdir, "LEA_NAME.csv"))

leanames <- unique(lea$LEA_NAME) %>% sort()

#generate simple keys for each unique LEA_NAME. this is to reduce the ultimate JSON file size (rather than relying on COMBOKEY)
leakey0 <- tibble(LEA_NAME=leanames, lea_key=1:length(leanames))
#which(duplicated(leakey0$lea_key))

#merge LEA_NAME keys onto original data set. this completes the link between COMBOKEY and our generated lea_key
leakey <- inner_join(lea, leakey0, by="LEA_NAME") %>% select(COMBOKEY, LEA_NAME, lea_key) %>% arrange(lea_key)

leakey2 <- setNames(leakey0, NULL)

write_json(leakey2, path=paste0(outputdir,"lea_names.json"), pretty=FALSE, na="null")

############# SCHOOLS ##############

schools0 <- read_csv(paste0(inputdir,"physical_school_data_nov_18.csv")) %>% mutate(SCH_NAME2 = sub("\xa0|\xb2", "", SCH_NAME))
#note, remove escaped unicode (only present in two schools)
schools0 %>% select(SCH_NAME, SCH_NAME2) %>% filter(SCH_NAME != SCH_NAME2)

#merge on the lea_key created above and select variables
schools1 <- schools0 %>% inner_join(leakey, by="COMBOKEY") %>%
                                select(lat="LAT",
                                lon="LON", 
                                name="SCH_NAME2",
                                d1="DOMAIN1",
                                d2="DOMAIN2",
                                d3="DOMAIN3",
                                d4="DOMAIN4",
                                cat = "EDUCATIONAL_OPP_CATEGORY",
                                key = "lea_key")

schools2 <- setNames(schools1, NULL)
  
write_json(schools2, path=paste0(outputdir,"schools.json"), digits=5, pretty=FALSE, na="null")


############# TRACTS ##############
main0 <- read_csv(paste0(inputdir,"final_data_11_18_physical_schools.csv"))

  main1 <- main0 %>% select(tract = "Tract.ID", 
                          le = "life_expectancy_at_start.15.24_plus_15", 
                          se = "life_expectancy_at_start_se.15.24", 
                          pov = "Percent_Under_Poverty_Level", 
                          white = "Percent_White", 
                          hispanic = "Percent_Hispanic", 
                          black = "Percent_Black", 
                          opp = "EDUCATIONAL_OPP")

#thresholds <- main1 %>% group_by(cat) %>% summarise(min=min(opp), max=max(opp)) %>% mutate(midpoint = (max+min)/2) %>% mutate(lemid = 77.87323 + (0.216148728*midpoint))

quantile(main1$opp, probs=(seq(0,1,0.1)), na.rm=TRUE)
quantile(main1$le, probs=(seq(0,1,0.2)), na.rm=TRUE)


#round values to 3 digits to cut down on JSON file size
main2 <- main1 %>% mutate_at(vars(pov, white, hispanic, black, opp), round, digits=3)

#remove names so JSON is an array of array -- useful for preserving type (versus CSV) and minimizing file size
main3 <- setNames(main2, NULL)

write_json(main3, path=paste0(outputdir,"le.json"), digits=5, pretty=FALSE, na="null")


####  confidence interval data

ci0 <- read_csv(paste0(inputdir,"ConfidenceIntervalDec13.csv")) %>% select(opp=EDUCATIONAL_OPP, le=LOWERLIMIT, le2=UPPERLIMIT)
ci1 <- setNames(ci0, NULL)

cidiffs <- ci0 %>% mutate(diff = le2-le)

write_json(ci1, path=paste0(outputdir,"ci.json"), digits=5, pretty=FALSE, na="null")


