////////// Need to edit 3 file paths:
const path_to_d3_node_module = '/abc/abc/abc/node/lib/node_modules/d3/dist/d3.js';
const path_to_geojson_directory = '/abc/abc/city_centroids/build/geojson/';
const output_directory = '/abc/abc/city_centroids/output/';
//////////

const d3 = require(path_to_d3_node_module);

const fips = ["01", "02", "04", "05", "06", "08", "09", "10", "11", 
"12", "13", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", 
"25", "26", "27", "28", "29", "30", "31", "32", "33", "34", "35", 
"36", "37", "38", "39", "40", "41", "42", "44", "45", "46", "47", 
"48", "49", "50", "51", "53", "54", "55", "56"]

var fs = require("fs");

var features = fips.map(function(f){
    var content = fs.readFileSync(path_to_geojson_directory + f + ".json", {"encoding":"utf8"});
    var json = JSON.parse(content);
    return json.features;
})

var flattened = features.flat();

console.log("Num features:");
console.log(flattened.length);
console.log("First feature:");
console.log(flattened[0]);

var centroids0 = flattened.map(function(feat){
    var centroid = d3.geoCentroid(feat);
    var f = feat.properties;
    return {name:f.NAME, state:f.STATEFP, stfips:f.STATEFP, centroid:centroid, GEOID:f.GEOID}
})

//final list of cities, keyed using city-statefips
var final_list = {"Birmingham-01":1,"Mobile-01":1,"Anchorage-02":1,"Fairbanks-02":1,"Juneau-02":1,"Flagstaff-04":1,"Phoenix-04":1,"Little Rock-05":1,"Los Angeles-06":1,"San Diego-06":1,"San Francisco-06":1,"Sacramento-06":1,"Grand Junction-08":1,"Denver-08":1,"Hartford-09":1,"Wilmington-10":1,"Washington-11":1,"Jacksonville-12":1,"Miami-12":1,"Tampa-12":1,"Atlanta-13":1,"Savannah-13":1,"Urban Honolulu-15":1,"Boise City-16":1,"Idaho Falls-16":1,"Springfield-17":1,"Chicago-17":1,"Fort Wayne-18":1,"Indianapolis city (balance)-18":1,"Cedar Rapids-19":1,"Des Moines-19":1,"Iowa City-19":1,"Wichita-20":1,"Bowling Green-21":1,"Lexington-Fayette-21":1,"Louisville/Jefferson County metro government (balance)-21":1,"New Orleans-22":1,"Shreveport-22":1,"Bangor-23":1,"Portland-23":1,"Baltimore-24":1,"Boston-25":1,"Detroit-26":1,"Grand Rapids-26":1,"Marquette-26":1,"Duluth-27":1,"Minneapolis-27":1,"Jackson-28":1,"Kansas City-29":1,"Springfield-29":1,"St. Louis-29":1,"Billings-30":1,"Great Falls-30":1,"Grand Island-31":1,"Omaha-31":1,"Las Vegas-32":1,"Reno-32":1,"Manchester-33":1,"Trenton-34":1,"Albuquerque-35":1,"Buffalo-36":1,"New York-36":1,"Albany-36":1,"Charlotte-37":1,"Raleigh-37":1,"Bismarck-38":1,"Fargo-38":1,"Cleveland-39":1,"Columbus-39":1,"Oklahoma City-40":1,"Tulsa-40":1,"Eugene-41":1,"Portland-41":1,"Scranton-42":1,"Philadelphia-42":1,"Pittsburgh-42":1,"Providence-44":1,"Charleston-45":1,"Columbia-45":1,"Rapid City-46":1,"Sioux Falls-46":1,"Knoxville-47":1,"Memphis-47":1,"Nashville-Davidson metropolitan government (balance)-47":1,"El Paso-48":1,"Dallas-48":1,"Houston-48":1,"Austin-48":1,"Salt Lake City-49":1,"St. George-49":1,"Burlington-50":1,"Norfolk-51":1,"Richmond-51":1,"Roanoke-51":1,"Seattle-53":1,"Spokane-53":1,"Charleston-54":1,"Morgantown-54":1,"Green Bay-55":1,"Milwaukee-55":1,"Casper-56":1,"Cheyenne-56":1};

var counts = {};

centroids0.forEach(function(d){
    var key = d.name + "-" + d.stfips;
    if(final_list.hasOwnProperty(key)){
        if(counts.hasOwnProperty(d.stfips)){
            counts[d.stfips].push(d);
        }
        else{
            counts[d.stfips] = [d];
        }
        final_list[key] = 0;
    }
});

var centroids = Object.entries(counts)

//sort subarray by place name
centroids.forEach(function(d){
    d[1].sort(function(a, b){
        return d3.ascending(a.name, b.name);
    });
});

//sort by state
centroids.sort(function(a,b){
    return d3.ascending(a[0], b[0])
});

var asJSON = JSON.stringify(centroids, null, 2);

fs.writeFileSync(output_directory + "city_centroids.json", asJSON)

//console.log("Not found:");
//for(var f in final_list){
//    if(final_list[f] === 1){
//        console.log(f);
//    }
//}
