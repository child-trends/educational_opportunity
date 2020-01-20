############################################
###    Code for Data Preparation         ###
############################################

A. R scripts for gathering and cleaning data
  1.	1_Merge_crdc.R - Merges together the Civil Rights Data Collection data
  2.	2_Merge_data.R - Aggregates together all other data sources
  3.	3_Match_highschool_to_census_tract.R - Matches high schools to census tracts

B. Code to create and analyze educational opportunity measures
  1.	4_Educational Opportunity Measure.R - Uses data aggregated in step A to calculate educational opportunity measure
  2.	5_Model.R - Runs regression analysis, and calculates confidence interval 

#################################
###    Code for visualization ###
#################################

A. Software for processing raw data (See source code for both R and Node package requirements)
- R (https://cran.r-project.org/)
- Node.js (https://nodejs.org/)

B. Raw data inputs. These data files are created by the code in the data preparation section:
  1. LEA_NAME.csv - School district names
  2. physical_schools.csv - Nearly 24k records containing school-level details
  3. census_tracts.csv - Census tract-level data containing life expectancy and other tract characteristics 
  4. ConfidenceIntervals.csv - Approximation of the confidence interval for the interactive scatter plot

C. Data processing scripts and JSON data outputs
  1. import_process_export.R - Process B.1, B.2, B.3, and B.4 to produce:
      1. lea_names.json
      2. schools.json
      3. le.json
      4. ci.json
  2. make_geojson.R - Pull place-level shapefiles from Census and convert to GeoJSON
  3. get_lon_lat.js  - Generate centroids from GeoJSON created by C.2 to produce:
      1. city_centroids.json 
  
D. External libraries for website front-end
  1. MapBox GL JS
      1. https://api.mapbox.com/mapbox-gl-js/v1.2.0/mapbox-gl.js
      2. https://api.mapbox.com/mapbox-gl-js/v1.2.0/mapbox-gl.css
  2. Vega JS (https://vega.github.io/vega/)
  3. D3.js (https://d3js.org/)
  4. enter-view.js (https://github.com/russellgoldenberg/enter-view)

E. JS source code for final construction of map and interactive scatter plot
  1. data-import.js 
    - Data retrieval and pre-processing for map
    - Handles import of all JSON data sources: C.1.i, C.1.ii, C.1.iii, C.1.iv, and C.3.i
  2. draw-map.js - Construction of Mapbox map
  3. draw-scatter.js - Construction of interactive scatter plot
