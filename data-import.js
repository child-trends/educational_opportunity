export default function data_import(){
  
  function url_(filename){
    //return "./data/" + filename;
    return "https://www.childtrends.org/wp-content/uploads/assets/usaleep/data/" + filename;
  }

  // ### TRACT PROCESSING FUNCTIONS

  function build_tract_lookup(rows){
    var lookup = {};

    rows.forEach(function(d){
      lookup[d.tract] = {le: d.le, se: d.se}
    });

    return lookup;
  }


  function build_mapbox_filters(rows){

    //life expectancy filters based on quantiles
    //breaks are result of R expression `quantile([LE], probs=c(0.2,0.4,0.6,0.8), na.rm=TRUE)`
    //last break is for >= condition, others are < condition
    var breaks = [76.1, 78.3, 80.2, 82.3, 82.3];
    var nbreaks = breaks.length;

    var quantile_colors = ['#eeeeee', '#b8b8b8', '#777777', '#3b3b3b', '#000000'];

    var quantile_filters = breaks.map(function(d,i){
      return {id:"tracts" + (i+1), threshold:d, color:quantile_colors[i], filter:["in", "GEOID"]}
    });
    

    //poverty filters (see below for thresholds)
    var poverty_filters = {
      low: ["in", "GEOID"],
      moderate: ["in", "GEOID"],
      high: ["in", "GEOID"]
    }

    //race/ethnicity filters
    var demographic_filters = {
      white: {
        low: ["in", "GEOID"],
        medium: ["in", "GEOID"],
        high: ["in", "GEOID"]
      },
      hispanic: {
        low: ["in", "GEOID"],
        medium: ["in", "GEOID"],
        high: ["in", "GEOID"]
      },
      black: {
        low: ["in", "GEOID"],
        medium: ["in", "GEOID"],
        high: ["in", "GEOID"]
      }
    }

    //missing tracts and NA filters
    var na_filter = ["in", "GEOID"];
    var notin_filter = ["!in", "GEOID"];

    //loop through rows, placing tracts in relevant filters
    rows.forEach(function(row, iii){

      // 1] LE quantile filters
      var le = row.le;
      var quantile_found = false;

      if(le != null){
        for(var i=0; i<nbreaks-1; i++){
          if(le < breaks[i]){
            quantile_filters[i].filter.push(row.tract);
            quantile_found = true;
            break;
          }
        }

        if(!quantile_found && le >= breaks[nbreaks-1]){
          quantile_filters[nbreaks-1].filter.push(row.tract);
        }
        else if(!quantile_found){
          console.log("No quantile filter");
        }

      }
      else{

        // le is na (0 observations, so not using)
        na_filter.push(row.tract)
      }

      // 2] poverty thresholds: low (<10%), moderate (10-20%), high (>20%)
      if(row.pov < 10){
        poverty_filters.low.push(row.tract);
      }
      else if(row.pov < 20){
        poverty_filters.moderate.push(row.tract);
      }
      else if(row.pov >= 20){
        poverty_filters.high.push(row.tract);
      }
      else{
        console.log("No poverty filter");
      }

      // 3] race/ethnicity thresholds: low (<20%), medium (20-60%), high (>60%)
      (["white", "black", "hispanic"]).forEach(function(group){
        if(row[group] < 20){
          demographic_filters[group].low.push(row.tract);
        }
        else if(row[group] < 60){
          demographic_filters[group].medium.push(row.tract);
        }
        else if(row[group] >= 60){
          demographic_filters[group].high.push(row.tract);
        }
        else{
          console.log("No demographic filter: " + group);
        }        
      });

      // 4] a filter that contains all tracts in data.
      //    if a tract is in vector tile source and not in data, it is "notin"
      notin_filter.push(row.tract);
    }); //end row loop

    return {
      quantile_filters: quantile_filters, 
      poverty_filters: poverty_filters,
      demographic_filters: demographic_filters,
      notin: notin_filter
    }

  }



  // ### SCHOOL PROCESSING FUNCTIONS

  function toGeoJSON(rows){
    //build geojson
    var features = rows.map(function(d, i){
      return {"type": "Feature", "geometry": {"type": "Point", "coordinates": [d.lon, d.lat]}, "properties": d}
    })

    return {"type":"FeatureCollection", "features":features}
  }

  //build color expression
  function schoolColorExpression(rows){
      var levels = ["#f26721", "#ff9850", "#b5e3fd", "#60b0f1", "#007cc2"];
      var oppscale = d3.scaleOrdinal().domain([1,2,3,4,5]).range(levels);
      
      var cols = {};
      levels.forEach(function(c){
        cols[c] = [];
      })

      //push each school id onto one of the 5 color arrays stored in cols
      rows.forEach(function(row){
        var col = oppscale(row.cat); 
        cols[col].push(row.id);
      })

      //build up the MapBox expression (see: https://docs.mapbox.com/mapbox-gl-js/style-spec/#expressions)
      var expression = ["match", ["get", "id"]]

      for(var color in cols){
        if(cols.hasOwnProperty(color)){
          //push array of school ids, followed by the color
          expression.push(cols[color], color)
        }
      }

      expression.push("#dddddd");

      return expression;
  }

  // ** DATA RETRIEVAL

  //tract level life expectancy data
  var le_data = d3.json(url_("le.json")).then(function(le_array){

    var ROWS = le_array.map(function(d){
      return {
        tract: d[0], 
        le: d[1], 
        se: d[2], 
        pov: d[3], 
        white: d[4], 
        hispanic: d[5], 
        black: d[6], 
        opp: d[7]
      }
    });

    var lookup = build_tract_lookup(ROWS);
    var filters = build_mapbox_filters(ROWS);

    return {lookup: lookup, filters:filters, table:ROWS}

  }, 
  function(e){throw new Error("Failed to retrieve LE data")});

  var lea_names = d3.json(url_("lea_names.json")).then(function(lea_array){
    var lookup = {};
    lea_array.forEach(function(d){
      lookup[(d[1]+"")] = d[0];
    });

    return lookup;

  },
  function(e){throw new Error("Failed to retrieve LEA names data")});

  //physical schools data
  var schools_data = d3.json(url_("schools.json")).then(function(schools_array){

    var ROWS = schools_array.map(function(d, i){
      return {
        lat: d[0], 
        lon: d[1], 
        name: d[2], 
        d1: d[3], 
        d2: d[4], 
        d3: d[5], 
        d4: d[6], 
        cat: d[7],
        lea: d[8],
        id: i
      }
    });

    var geoj = toGeoJSON(ROWS);
    var expression = schoolColorExpression(ROWS)

    return {geojson:geoj, color:expression, table:ROWS}

  },
  function(e){throw new Error("Failed to retrieve schools data")});

  var city_centroids = d3.json(url_("city_centroids.json"))
                        .catch(function(e){throw new Error("Failed to retrieve centroids")});

  var ci = d3.json(url_("ci.json")).then(function(rows){
    return rows.map(function(d){
      return {opp:d[0], le:d[1], le2:d[2]}
    })
  },
  function(e){throw new Error("Failed to retrieve CI data")});

  return Promise.all([le_data, schools_data, city_centroids, ci, lea_names]);
}