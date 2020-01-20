export default function draw_map(tract_data, schools_data, city_centroids, lea_lookup){
    //Use of these vector tile sources with Mapbox was documented in a blog post from the Census Bureau: https://uscensusbureau.github.io/citysdk/examples/mapbox-choropleth/
    var mapstyle = {
        "version": 8,
        "name": "TractMap",
        "sources": {
            "tractData": {
                "type": "vector",
                "tiles": [
                    "https://gis-server.data.census.gov/arcgis/rest/services/Hosted/VT_2015_140_00_PY_D1/VectorTileServer/tile/{z}/{y}/{x}.pbf"
                ],
                "maxzoom":15
            },
            "states": {
                "type":"vector",
                "tiles": [
                "https://gis-server.data.census.gov/arcgis/rest/services/Hosted/VT_2010_040_00_LN_D1/VectorTileServer/tile/{z}/{y}/{x}.pbf"
                ]
            },
            "places": {
                "type":"vector",
                "tiles": [
                "https://gis-server.data.census.gov/arcgis/rest/services/Hosted/VT_2018_160_00_PY_D1/VectorTileServer/tile/{z}/{y}/{x}.pbf"
                ]
            },
            "districts": {
                "type":"vector",
                "tiles":[
                "https://gis-server.data.census.gov/arcgis/rest/services/Hosted/VT_2015_970_00_PY_D1/VectorTileServer/tile/{z}/{y}/{x}.pbf"
                ]
            }
        },
    
        "glyphs": "https://gis-server.data.census.gov/arcgis/rest/services/Hosted/VT_2018_160_00_PY_D1/VectorTileServer/resources/fonts/{fontstack}/{range}.pbf",
    
        "layers": [
    
            {
                id: "states",
                type: "line",
                source: "states",
                "source-layer": "StateLine",
                paint: {
                "line-color": "#999999",
                "line-width":5,
                },
                layout: {
                "line-join": "round",
                "line-cap": "round"
                }
            },
            {
                id: "district_outlines",
                type: "line",
                source: "districts",
                "source-layer": "UnifiedSchoolDistrict",
                paint: {
                    "line-color": "#EBBC4E",
                    "line-width":1.5,
                    "line-dasharray": [3,6]
                },
                layout: {
                    "line-join": "round",
                    "line-cap": "round"
                }
            },
    
            {
                id: "place_names",
                type: "symbol",
                source: "places",
                "source-layer": "Place/label",
                "layout": {
                "text-field":"{_name}",
                "text-font":["literal", ["Arial Regular"]],
                "text-size":15,
                "text-padding":25,
                },
                "paint": {
                    "text-color": "#000000",
                    "text-halo-color": "#eeeeee",
                    "text-halo-width": 1.5
                }
            }
        ]
    }

    //add the schools geojson as a source
    mapstyle.sources.schools = {
        "type": "geojson",
        "data": schools_data.geojson
    }



    mapstyle.layers.unshift({
        id: "schools",
        type: "circle",
        source: "schools",
        paint: {
        "circle-radius": 6,
        "circle-color":schools_data.color,
        "circle-opacity":1,
        "circle-stroke-width":1,
        "circle-stroke-color":"#222222"
        }
    });

    mapstyle.layers.unshift({
        id: "schools_blur",
        type: "circle",
        source: "schools",
        paint: {
        "circle-radius": 10,
        "circle-color":"#333333",
        "circle-blur": 0.75,
        "circle-opacity":1,
        "circle-stroke-width":0,
        "circle-stroke-color":"#222222"
        }
    });

    //add in layers for filtered tracts
    //quantile_filter id/key vals: tracts1, tracts2, ..., tracts5 (low to high LE)
    var quantile_filters = {};
    var num_filtered = 0;

    tract_data.filters.quantile_filters.forEach(function(d,i){
        mapstyle.layers.unshift({
            "id": d.id,
            "type": "fill",
            "source": "tractData",
            "source-layer": "CensusTract",
            "filter": d.filter,
            "paint":{
                "fill-opacity": 1,
                "fill-color": d.color,
                "fill-outline-color":"#999999"
            }
        })

        quantile_filters[d.id] = d.filter;
        num_filtered = num_filtered + d.filter.length - 2
    })

    //used for QA testing -- not visible here
    mapstyle.layers.unshift({
        "id": "notin",
        "type": "fill",
        "source": "tractData",
        "source-layer": "CensusTract",
        "filter":tract_data.filters.notin,
        "paint":{
            "fill-opacity": 0,
            "fill-color": "yellow",
            "fill-outline-color":"#999999"
        }        
    })

    //build map
    var map = new mapboxgl.Map({
        container: "map",
        style: mapstyle, 
        center: {
        lat: 39.1,
        lng: -76.8
        },
        zoom: 10,
        minZoom: 9,
        pitchWithRotate: false,
        dragRotate: false
    });

    map.addControl(new mapboxgl.NavigationControl({showZoom:true, showCompass:false}), "top-left");
    map.scrollZoom.disable();

    var tracts_disabled = false;

    function clickHandler(e){
        var lngLat = e.lngLat;

        var html = "<p>";
        if(e.features.length == 1){
            var data = tract_data.lookup[e.features[0].properties.GEOID];

            if(data != null){
                html = html + "Life expectancy<br/>" + data.le + " +/-" + Math.round(1.960*data.se*10)/10 + " years";
            }
            else{
                html = html + "Data not available: " + e.features[0].properties.GEOID;
            }
        }
        html = html + "</p>";

        if(!tracts_disabled){
            new mapboxgl.Popup()
            .setLngLat(lngLat)
            .setHTML(
                html
            )
            .addTo(map);
        }        
    }

    map.on("click", "tracts1", clickHandler);
    map.on("click", "tracts2", clickHandler);
    map.on("click", "tracts3", clickHandler);
    map.on("click", "tracts4", clickHandler);
    map.on("click", "tracts5", clickHandler);

    map.on("click", "notin", clickHandler);

    var school_popups = [];

    var offsets = [[0,0], [-10,-10], [10,-10], [10,10], [-10,10]]
 
    map.on("click", "schools", function(e){
        school_popups.forEach(function(p){
            p.remove();
        });

        e.features.forEach(function(feat, i){
            var school = feat.properties;
            var offset = offsets[i%5];
            var lea = lea_lookup.hasOwnProperty(school.lea) ? lea_lookup[school.lea] : null;
            school_popups.push(
                new mapboxgl.Popup({"maxWidth":"330px", "offset":offset})
                .setLngLat([school.lon, school.lat])
                .setHTML(
                '<p>' +
                '<span>' + school.name + '</span><br/>' + 
                '<span class="lea-name">' + (lea !== null ? lea.toUpperCase() : "") + '</span><br />' + 
                '<span>Access to rigorous academics: ' + school.d1 + ' of 5</span><br/>' + 
                '<span>Access to supportive conditions for learning: ' + school.d2 + ' of 5</span><br/>' + 
                '<span>Access to appropriate nonacademic supports: ' + school.d3 + ' of 5</span><br/>' + 
                '<span>Access to effective teaching: ' + school.d4 + ' of 5</span><br/>' + 
                '<strong>Overall: ' + school.cat + ' of 5</strong>' +
                '</p>'
                )
                .addTo(map)
            );  
        });

    });

    map.on("mouseenter", "schools", function(d){
        tracts_disabled = true;
        document.getElementById("map").classList.add("map-pointer");
    });

    map.on("mouseleave", "schools", function(d){
        tracts_disabled = false;
        document.getElementById("map").classList.remove("map-pointer");
    });

    //build out filter menu
    map.on("load", function(){
        var filterLookup = {
            pov1: tract_data.filters.poverty_filters.low,
            pov2: tract_data.filters.poverty_filters.moderate,
            pov3: tract_data.filters.poverty_filters.high
        }

        var filterOptions = [
            {
                label: "Poverty",
                filters: [
                    {id:"pov1", label:"Poverty < 10%"},
                    {id:"pov2", label:"Poverty 10%–20%"},
                    {id:"pov3", label:"Poverty >= 20%"}
                ]
            }
        ]

        var threshold_labels = {"low":"< 20%", "medium":"20%–60%", "high":">= 60%"}
        var group_labels = {"White":"Percentage white", "Hispanic":"Percentage Hispanic", "Black":"Percentage Black"}
        var groups = ["White", "Hispanic", "Black"];
        var thresholds = ["low","medium","high"];


        groups.forEach(function(group){
            
            var optgroup = {
                label: group_labels[group],
                filters: []
            }

            var grouplc = group.toLowerCase();

            thresholds.forEach(function(threshold, i){
                var id = grouplc + i + "";
                
                optgroup.filters.push({id:id, label:group + " " + threshold_labels[threshold]});

                filterLookup[id] = tract_data.filters.demographic_filters[grouplc][threshold];
            });

            filterOptions.push(optgroup);
        });

        var select = d3.select("#filter-box").append("select").style("width","100%").style("margin","5px 0px");
        select.append("option").attr("value","none").text("Show all");
        var optg = select.selectAll("optgroup").data(filterOptions).join("optgroup").attr("label", function(d){return d.label});
        
        var options = optg.selectAll("option").data(function(d){return d.filters}).join("option")
                .text(function(d){
                    return d.label;
                })
                .attr("value", function(d){return d.id})
                ;

        select.on("change", function(){
            var id = this.value;
            var f = filterLookup.hasOwnProperty(id) ? filterLookup[id] : null;

            //combine filter with filter of each tract layer
            ([1,2,3,4,5]).forEach(function(n){
                var id = "tracts" + n;
                var le_filter = quantile_filters[id];

                var ff = f === null ? le_filter : ["all", le_filter, f]
                
                map.setFilter(id, ff);
            });

        });

        map.on("dragend", function(){
            city_info();
        });

        city_info();

        locate_me("enter");

    });

    var flat_centroids = [];
    city_centroids.forEach(function(d){
        d[1].forEach(function(dd){
            flat_centroids.push(dd);
        })
    })

    function in_bbox(centroid, map_bounds){

        return centroid[0] > map_bounds._sw.lng && centroid[0] < map_bounds._ne.lng &&
               centroid[1] > map_bounds._sw.lat && centroid[1] < map_bounds._ne.lat;
    }

    function dist_from_center(centroid, map_center){
        var y = map_center.lat - centroid[1];
        var x = map_center.lng - centroid[0];
        var dist = Math.sqrt(Math.pow(x,2) + Math.pow(y,2));
        return dist;
    }


    function city_info(){
        var map_center = map.getCenter();
        var map_bounds = map.getBounds();

        var closest_city = {
            GEOID:null,
            distance:null
        }

        flat_centroids.forEach(function(d){
            var dist = dist_from_center(d.centroid, map_center);
            var in_bounds = in_bbox(d.centroid, map_bounds);

            if(in_bounds){
                if(closest_city.distance === null || dist < closest_city.distance){
                    closest_city.distance = dist;
                    closest_city.GEOID = d.GEOID;
                    closest_city.name = d.name;
                }
            }
        });

        city_text(closest_city.GEOID);
    }


    //build out city select menu
    var centroids = {};

    city_centroids.forEach(function(d){
        d[1].forEach(function(dd){
            centroids[dd.GEOID] = dd.centroid;
        })
    });

    var select = d3.select("#select-box").append("select").style("width","100%").style("margin","5px 0px");
    var optgroups = select.selectAll("optgroup").data(city_centroids).join("optgroup").attr("label", function(d){return d[0]});
    
    var options = optgroups.selectAll("option").data(function(d){return d[1]}).join("option")
            .text(function(d){
                var s0 = d.name.split("-")[0];
                var s1 = s0.split("/")[0];
                return s1;
            })
            .attr("value", function(d){return d.GEOID})
            ;

    var current_city = null;
    select.on("change", function(){
        var geoid = this.value;
        if(geoid != current_city && centroids.hasOwnProperty(geoid)){
            var c = centroids[geoid];
            map.jumpTo({
                    center: {
                        lat: c[1],
                        lng: c[0]
                    }
                });
            current_city = geoid;
            city_info();
        }
    });

    var help_shown = true;
    var help_button = d3.select("#help-button");
    var help_button_text = help_button.select("p");
    var control_box = d3.select("#control-box");
    var control_box_anno = d3.select("#control-box-anno");
    var ov = d3.select("#total-map-overlay");

    function toggle_help(){
        help_shown = !help_shown;

        
        ov.style("z-index", help_shown ? null : 0)
          .style("opacity", help_shown ? 1 : 0);

        control_box.style("z-index", help_shown ? 50 : null);
        control_box_anno.style("display", help_shown ? "block" : null);

        

        help_button_text.text(help_shown ? "X" : "?");
    }

    toggle_help();

    help_button.on("mousedown", toggle_help);

    function locate_me(ev){
        if("geolocation" in navigator && ev == "enter") {
            try{
                navigator.geolocation.getCurrentPosition(
                    function(position){
                        map.jumpTo({
                            center:{
                                lat: position.coords.latitude, 
                                lon: position.coords.longitude
                            }
                        });
                        city_info();
                    }
                );
            }
            catch(e){
                //console.log("No geolocation");
            }
        } 

    }

    //guide_me is deprecated
    function guide_me(show){
        d3.select("#key-box-anno").style("display", show>0 ? "block" : "none");
        d3.select("#key-box").style("z-index", show>0 ? 40 : 20).style("opacity", show>0 ? 1 : 0);

        d3.select("#control-box-anno").style("display", show>1 ? "block" : "none");
        d3.select("#cities_filters").style("z-index", show>1 ? 40 : 20).style("opacity", show>1 ? 1 : 0);
    }

    var map_city_text_wrap = d3.select("#map-city-text").style("display","none");
    
    var map_city_text_close = map_city_text_wrap.select(".close-box");
    var map_city_text_is_closed = false;
    var last_map_city_text = null;
    
    var all_city_texts = map_city_text_wrap.selectAll("p.city-text").style("display","none");
    var city_text_ = {
        "2404000":1,
        "2622000":1,
        "1150000":1,
        "0644000":1,
        "4260000":1,
        "1714000":1,
        "3137000":1,
        "4805000":1,
        "1304000":1,
        "1245000":1
    };

    map_city_text_close.on("mousedown", function(){
        map_city_text_wrap.style("display","none");
        map_city_text_is_closed = true;
    });

    function city_text(geoid){

        if(geoid !== last_map_city_text){
            map_city_text_is_closed = false;
        };

        if(geoid !== null && city_text_.hasOwnProperty(geoid) && !map_city_text_is_closed){
            last_map_city_text = geoid;
            map_city_text_wrap.style("display", "block");
            all_city_texts.style("display", function(){return geoid == this.id ? "block" : "none"});
        }
        else{
            map_city_text_wrap.style("display", "none");
            all_city_texts.style("display", "none");
        }
    }
    

}