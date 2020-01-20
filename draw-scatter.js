export default function draw_scatter(data, ci){

var padding = {"top":20, "right":60, "bottom":60, "left":60};

var spec = {
    "$schema": "https://vega.github.io/schema/vega/v5.json",
    "width": 600,
    "height": 400,
    "padding": padding,
    "autosize": {"type": "none"},

    "data":[
        {
            "name":"table0",
            "values":data
        },
        {
            "name": "table",
            "source": "table0",
            "transform": [
                {
                    "type": "filter",
                    "expr": "datum.le != null && datum.opp != null"
                }
            ]
        },
        {
            "name":"ci",
            "values": ci
        },
        {
            "name": "trend",
            "values": [
                {"opp": 0, "le": 77.87323 + (0.216148728 * 0)},
                {"opp": 10, "le": 77.87323 + (0.216148728 * 10)}
            ]
        },
        {
            "name": "bins",
            "source": "table",
            "transform": [
              {
                "type": "bin", 
                "field": "opp", 
                "step": 0.1,
                "extent": {"signal": "domain('xscale')"},
                "as": ["opp0", "opp1"]
              },
              {
                "type": "bin", 
                "field": "le", 
                "step": 1,
                "extent": {"signal": "domain('yscale')"},
                "as": ["le0", "le1"]
              },

              {
                "type": "aggregate",
                "groupby": ["opp0", "opp1", "le0", "le1"]
              }
            ]
        },
        {
            "name": "categories",
            "values":[
                {"cat":1,"min":0,"max":4.5786, "views":[2,4]},
                {"cat":2,"min":4.5786,"max":5.4282, "views":[null, null]},
                {"cat":3,"min":5.4282,"max":6.0487, "views":[1, null]},
                {"cat":4,"min":6.0487,"max":6.5699, "views":[null, null]},
                {"cat":5,"min":6.5699,"max":9.2263, "views":[3, 4]}
            ],
            "transform": [
                {
                    "type": "filter",
                    "expr": "view_number == datum.views[0] || view_number == datum.views[1]"
                }
            ]
        },
        {
            "name": "trend_values",
            "values": [
                {"opp": 3.81, "le":78.6, "views":[2, 4], "bold":true},
                {"opp": 5.77, "le":79.1, "views":[1, null], "bold":true},
                {"opp": 6.87, "le":79.4, "views":[3, 4], "bold":true}                
            ]
        },	  
        {
            "name": "ci_values",
            "values": [
                {"opp": 3.81, "le":71.9, "views":[2, null], "bold":false},
                {"opp": 3.81, "le":85.4, "views":[2, null], "bold":false},

                {"opp": 5.77, "le":72.4, "views":[1, null], "bold":false},
                {"opp": 5.77, "le":85.8, "views":[1, null], "bold":false},

                {"opp": 6.87, "le":72.7, "views":[3, null], "bold":false},
                {"opp": 6.87, "le":86.1, "views":[3, null], "bold":false}
            ]
        },
        {
            "name": "combined_values",
            "source": ["trend_values", "ci_values"],
            "transform": [
                {
                    "type": "filter",
                    "expr": "view_number == datum.views[0] || view_number == datum.views[1]"
                }
            ]
        },

        {
            "name":"comparison_tracts",
            "values":[
                {"opp":5.75004291728657, "le":76.8, "id":"domain 1"},
                {"opp":8.51057752507837, "le":80, "id":"domain 1"},

                {"opp":5.18132425730227, "le":75, "id":"domain 2"},
                {"opp":6.17290938873209, "le":76.1, "id":"domain 2"}
            ],
            "transform":[
                {
                    "type":"filter",
                    "expr":"datum.id == tract_highlight"
                }
            ]
        },

        {
            "name":"comparison_arrows",
            "values":[
                {"opp":8.51057752507837, "le":76.8, "view":6, "shape":"triangle-right"},
                {"opp":8.51057752507837, "le":80, "view":7, "shape":"triangle-up"},

                {"opp":6.17290938873209, "le":75, "view":null, "shape":"triangle-right"},
                {"opp":6.17290938873209, "le":76.1, "view":null, "shape":"triangle-up"}
            ],
            "transform":[
                {
                    "type":"filter",
                    "expr":"datum.view != null && view_number >= datum.view"
                }
            ]
        },


        {
            "name":"comparison_diffs",
            "values":[
                {"opp1":5.75004291728657, "opp2":8.51057752507837,  "le1":76.8, "le2":76.8, "id":"domain 1", "view":6},
                {"opp1":8.51057752507837, "opp2":8.51057752507837,  "le1":76.8, "le2":80, "id":"domain 1", "view":7},

                {"opp1":5.18132425730227, "opp2":6.17290938873209, "le1":75, "le2":75, "id":"domain 2", "view":null},
                {"opp1":6.17290938873209, "opp2":6.17290938873209, "le1":75, "le2":76.1, "id":"domain 2", "view":null}

            ],
            "transform":[
                {
                    "type":"filter",
                    "expr":"datum.view != null && view_number >= datum.view"
                }
            ]
        },

        {
            "name":"anno_text",
            "values":[

                {"xval":5.6, "yval":98, "view":1,
                "text":"The middle 20 percent of neighborhoods in terms of educational opportunity fall in this range. The average predicted life expectancy for 15-year-olds in these communities is 79.1 years"},
                {"xval":0.15, "yval":98, "view":2,
                "text":"Meanwhile, 15-year-olds in the bottom 20 percent of neighborhoods have an average predicted life expectancy of 78.6 years."},
                {"xval":6.7, "yval":98, "view":3,
                "text":"And in the top 20 percent of neighborhoods, there is an average predicted life expectancy of 79.4 years."},
                {"xval":6.7, "yval":98, "view":4,
                "text":"Teens in neighborhoods with high levels of educational opportunity can expect to live 0.7 years longer than their peers in neighborhoods with low educational opportunity."},
                {"xval":5.8, "yval":75, "view":5,
                "text":"Consider this example of two demographically similar neighborhoods, differentated mostly by a large gap in educational opportunity."},
                {"xval":5.8, "yval":75, "view":6,
                "text":"The gap is a result of a difference in access to rigorous academics equivalent to gaining access to AP courses, a dual enrollment program, and advanced math courses."},
                {"xval":5.8, "yval":75, "view":7,
                "text":"The difference in life expectancy between these two neighborhoods is 3.2 years."}
            ],
            "transform":[
                {
                    "type":"formula",
                    "expr":"scale('xscale', datum.xval)",
                    "as":"x"
                },
                {
                    "type":"formula",
                    "expr":"scale('yscale', datum.yval)",
                    "as":"y"
                },
                {
                    "type":"filter",
                    "expr":"datum.view == view_number"
                }
            ]
        }

    ],

    "signals": [

        {
            "name": "container_dims",
            "update": "containerSize()",
            "on": [
                {
                    "events": {"source": "window", "type": "resize"},
                    "update": "containerSize()"
                }
            ]
        },

        {
            "name": "container_width",
            "update": "container_dims[0]"
        },

        {
            "name":"width",
            "update":"container_width - 120 < 200 ? 320 : container_width - 120"
        },

        {
            "name":"height",
            "update":"container_dims[1] - 80"
        },

        {
            "name":"bub_area",
            "update": "1.5*(width*width)/10000"
        },

        {
            "name":"tract_highlight",
            "value":null
        },
        
        {
            "name":"show_scatter_elements",
            "value":false,
            "update": "tract_highlight == null"
        },

        {
            "name":"view_number",
            "value":-1
        }

    ],

    "scales": [
        {
            "name":"xscale",
            "type":"linear",
            "domain":[0,10],
            "range":"width",
            "round":true
        },
        {
            "name":"yscale",
            "type":"linear",
            "domain":[59, 99],
            "range":[{"signal":"height"}, 20],
            "zero": false
        },
        {
            "name": "size",
            "type": "linear",
            "zero": true,
            "domain": {"data": "bins", "field": "count"},
            "range": [0,{"signal":"bub_area"}]
        },
        {
            "name": "ci_fill",
            "type": "ordinal",
            "domain": ["Confidence interval"],
            "range": ["#facab1"]
        }
    ],

    "marks": [
        {
            "type": "rect",
            "name": "quintile_highlight",
            "from": {"data": "categories"},
            "zindex": 320,
            "encode":{
                "update":{
                    "x": {"signal":"scale('xscale',datum.min)"},
                    "x2": {"signal":"scale('xscale',datum.max)"},
                    "y": {"signal": "range('yscale')[0]"},
                    "y2": {"signal": "range('yscale')[1]"},
                    "fill":{"value":"#ffffff"},
                    "stroke":{"value":"#000000"},
                    "strokeWidth":{"value":1},
                    "cornerRadius":{"value":0},
                    "opacity":{"value":0.75}
                }
            }
        },

        {
            "type": "line",
            "name":"regression_line",
            "from": {"data": "trend"},
            "zindex": 200,
            "encode": {
              "update": {
                "x": {"scale": "xscale", "field": "opp"},
                "y": {"scale": "yscale", "field": "le"},
                "stroke": {"value": "#f26721"},
                "opacity":{"value":0.9},
                "strokeWidth": {"value": 3}
              }
            }
          },

          {
            "name": "ci_area",
            "type": "area",
            "from": {"data": "ci"},
            "zindex": 90,
            "encode": {
              "enter":{
                "interpolate": {"value":"linear"},
                "fill":{"value":"#facab1"}
              },  
              "update": {
                "x": {"scale": "xscale", "field": "opp"},
                "y": {"scale": "yscale", "field": "le"},
                "y2": {"scale": "yscale", "field": "le2"}
              }
            }
          },

          {
            "name": "bin_circles",
            "zindex":100,
            "type": "symbol",
            "from": {"data": "bins"},
            "interactive": {"signal": "show_scatter_elements"},
            "encode": {
              "update": {
                "x": {"scale": "xscale", "signal": "(datum.opp0 + datum.opp1) / 2"},
                "y": {"scale": "yscale", "signal": "(datum.le0 + datum.le1) / 2"},
                "size": {"scale": "size", "field": "count"},
                "shape": {"value": "circle"},
                "fill":{"signal":"show_scatter_elements ? '#000000' : '#000000'"},
                "opacity":{"signal":"show_scatter_elements ? 1 : 0.25"},
                "tooltip": {"signal":"['Life expectancy: <strong>' + datum.le0 + ' to ' + datum.le1 + '</strong>'," +
                                     "'Number of neighborhoods: <strong>' + datum.count + '</strong>']"}
              },
              "hover":{
                "fill": {"value": "#000000"}
              }
            }
          },

          {
              "name":"regression_label",
              "type":"text",
              "interactive":false,
              "zindex":100,
              "encode":{
                  "enter":{
                      "text":{"value":"Average relationship"},
                      "fontSize":{"value":"13"},
                      "angle":{"value":-1.7},
                      "align":{"value":"left"}
                  },
                  "update":{
                      "x":{"value":0.3, "scale":"xscale"},
                      "y":{"value":76.6, "scale":"yscale"},
                      "opacity":{"signal":"width < 780 ? 0 : 1"}
                  }
              }
          },

          {
            "name":"ci_label",
            "type":"text",
            "interactive":false,
            "zindex":100,
            "encode":{
                "enter":{
                    "text":{"value":"Confidence interval"},
                    "fontSize":{"value":"13"},
                    "angle":{"value":-1.7},
                    "align":{"value":"left"}
                },
                "update":{
                    "x":{"value":1, "scale":"xscale"},
                    "y":{"value":83.5, "scale":"yscale"},
                    "opacity":{"value":0}
                }
            }
        },

          {
              "name":"tract_highlights",
              "type":"symbol",
              "from": {"data": "comparison_tracts"},
              "zindex": 225,
              "encode":{
                  "update":{
                      "x":{"field":"opp", "scale":"xscale"},
                      "y":{"field":"le", "scale":"yscale"},


                      "strokeWidth":{"value":0},
                      "stroke":{"value":"#000000"},
                      "fill":{"value":"#000000"},
                      "size":{"value":90}
                  }
              }
          },

          {
            "name":"tract_arrows",
            "type":"symbol",
            "from": {"data": "comparison_arrows"},
            "zindex": 235,
            "encode":{
                "update":{
                    "x":{"signal":"scale('xscale', datum.opp) - (datum.shape=='triangle-right' ? 5 : 0)"},
                    "y":{"signal":"scale('yscale', datum.le) + (datum.shape=='triangle-up' ? 5 : 0)"},
                    "shape":{"signal":"datum.shape"},
                    "strokeWidth":{"value":1},
                    "stroke":{"value":"#ffffff"},
                    "fill":{"value":"#000000"},
                    "size":{"value":145}
                }
            }
        },

          {
            "name":"diffs",
            "type": "rule",
            "from": {"data": "comparison_diffs"},
            "zindex": 200,
            "encode": {
              "update": {
                "x": {"scale": "xscale", "field": "opp1"},
                "x2": {"scale": "xscale", "field": "opp2"},
                "y": {"scale": "yscale", "field": "le1"},
                "y2": {"scale": "yscale", "field": "le2"},
                "stroke": {"value": "#000000"},
                "strokeWidth": {"value": 2},
                "strokeDash": {"value":[3,3]}
              }
            }
          },

          {
              "name":"trend_points",
              "type":"rule",
              "from":{"data":"combined_values"},
              "zindex":330,
              "encode": {
                "update": {
                  "x": {"scale": "xscale", "field": "opp"},
                  "x2": {"scale": "xscale", "field": "opp"},
                  "y": {"signal":"scale('yscale', datum.le) + 4"},
                  "y2": {"signal":"scale('yscale', datum.le) - 4"},
                  "stroke": {"value": "#000000"},
                  "strokeWidth": {"value": 2},
                  "fontWeight": {"signal":"datum.bold ? 'bold' : 'normal'"},
                  "fontSize": {"signal":"datum.bold ? 18 : 15"},
                  "align": [
                    {"test": "datum.opp < 4", "value":"right"},
                    {"test": "datum.opp > 6", "value":"left"},
                    {"value":"center"}
                  ]
                }
              }
          },

          {
            "name":"trend_points_text",
            "from":{"data":"trend_points"},
            "interactive":false,
            "zindex":330,
            "type":"text",
            "encode":{
                "update":{
                    "x": {"field":"x"},
                    "y": {"signal":"datum.y2-3"},
                    "dx": [
                        {"test": "datum.align == 'left'", "value":-5},
                        {"test": "datum.align == 'right'", "value":5},
                        {"value":0} 
                    ],
                    "text": {"signal":"format(datum.datum.le, '.1f') + ' years'"},
                    "align": {"field":"align"},
                    "fontSize": {"field":"fontSize"},
                    "fontWeight": {"field":"fontWeight"}
                  }
            }
        },
        {
            "name":"trend_points_text0",
            "from":{"data":"trend_points_text"},
            "interactive":false,
            "zindex":329,
            "type":"text",
            "encode":{
                "update":{
                    "x": {"field":"x"},
                    "y": {"field":"y"},
                    "dx": {"field":"dx"},
                    "text": {"field":"text"},
                    "align": {"field":"align"},
                    "fontSize": {"field":"fontSize"},
                    "fontWeight": {"field":"fontWeight"},

                    "fill":{"value":"#ffffff"},
                    "stroke":{"value":"#ffffff"},
                    "strokeWidth":{"value":4},
                    "strokeOpacity":{"value":1}
                  }
            }
        }
    ],

    "axes": [
        {
            "scale": "xscale",
            "grid": false,
            "orient": "bottom",
            "tickCount": 5,
            "title": "Educational opportunity",
            "titlePadding": {"signal":"width < 600 ? 5 : -10"},
            "labelPadding": 15,
            "encode":{
                "labels":{
                    "update":{
                        "text": [
                            {"test":"datum.value == 0", "value":"◂ ◂ ◂ Lower"},
                            {"test":"datum.value == 10", "value":"Higher ▸ ▸ ▸"},
                            {"value":""}
                        ],
                        "align": [
                            {"test":"datum.value == 0", "value":"left"},
                            {"test":"datum.value == 10", "value":"right"},
                            {"value":"center"}
                        ],
                        "dx": [
                            {"test":"datum.value == 0", "value":15},
                            {"test":"datum.value == 10", "value":-15},
                            {"value":0}
                        ]
                    }
                }
            }
        },
        {
            "scale": "yscale",
            "grid": true,
            "orient": "left",
            "titlePadding":15,
            "title": "Life expectancy",
            "titleAnchor": "end"
        }
    ],

    "legends": [
        {
            "size": "size",
            "orient": "bottom-right",
            "direction":"horizontal",
            "values":[50, 150, 300],
            "title":"Number of neighborhoods",
            "columns": 4,
            "colPadding": 0,
            "cornerRadius": 12,
            "strokeColor": "none",
            "strokeWidth": 0,
            "labelFontSize": 15,
            "titleFontSize": 15,
            "titlePadding": 10,
            "titleLimit": 350,
            "format": ",.0f",
            "symbolFillColor": "#000000",
            "symbolStrokeWidth":0,
            "symbolOffset":0,
            "gridAlign":"each",
            "padding":10,
            "fillColor":"#ffffff",
            "zindex":30,
            "titleOpacity":{"signal":"show_scatter_elements ? 1 : 0"},
            "symbolOpacity":{"signal":"show_scatter_elements ? 1 : 0"},
            "labelOpacity":{"signal":"show_scatter_elements ? 1 : 0"},
            "encode":{
                "legend":{
                    "update":{
                        "opacity":{"signal":"show_scatter_elements ? 1 : 0"}
                    }
                },
                "symbols":{
                    "update":{
                        "x":{"signal":"sqrt(scale('size',datum.value))/2"}
                    }
                },
                "labels":{
                    "update":{
                        "x":{"signal":"sqrt(scale('size',datum.value))"},
                        "dx":{"value":3}
                    }
                }
            }
        },
        {
            "fill":"ci_fill",
            "orient": {"signal":"width < 600 ? 'top-right' : 'bottom-left'"},
            "padding": 10,
            "encode":{
                "symbols":{
                    "enter":{
                        "shape":{"value":"square"},
                        "size":{"value":300}
                    }
                }
            }
        }
    ]

} //end vega specification


//generic theme. many items are overridden in above specification
var fontFamily = "'Lato', sans-serif";
var theme = {
    "text":{
        "font": fontFamily,
        "fontSize":15,
        "fill":"#111111"
        },
    "legend":{
        "layout":{
            "anchor": "start",
            "margin":40
            },
        "titleFontWeight": "700",
        "titleColor": "#111111",
        "labelColor": "#111111",
        "titleFont": fontFamily,
        "titleFontSize": 16,
        "labelFont": fontFamily,
        "labelFontSize": 16,
        "columnPadding":20
        },
    "axis":{
        "labelFont": fontFamily,
        "labelFontSize": 16,
        "labelColor": "#111111",
        "titleColor": "#111111",
        "titleFontWeight":"700",
        "titleFontSize":18,
        "titlePadding":12
    }
} //end theme

//DOM setup

//outer wrap
var outer_wrap = d3.select("#main-scatter").append("div").style("position","relative")
                    .style("padding","0px").style("margin","0px");

//chart wrapper
var chart_wrap = outer_wrap.append("div").style("padding","0px").style("margin","0px").classed("scatter-wrap",true);

//tooltip sits in outer
var tip_width = 225;
var tooltip = outer_wrap.append("div").style("position","absolute")
                .style("display","none").style("width",tip_width + "px")
                .classed("chart-tooltip",true);

var anno = outer_wrap.append("div").style("position","absolute")
                .style("display","none").style("max-width", "320px")
                .classed("chart-tooltip",true);

var title = d3.select("#scatter-title").style("margin-bottom","0px");

var view = new vega.View(vega.parse(spec, theme));

view.hover()
    .initialize(chart_wrap.node())
    .renderer("svg")
    .tooltip(tooltip_handler)
    .runAsync()

view.addDataListener("anno_text", function(n, d){
    if(d !== null && d.length > 0){
        var w = view.signal("width");
        var x = padding.left + "px";
        var y = "70%";
        
        try{
            if(w < 600){throw new Error("Too narrow")}
            x = (d[0].x + padding.left) + "px";
            y = (d[0].y + padding.top) + "px"
            anno.style("max-width", "320px");
        }
        catch(e){
            anno.style("max-width", "600px");
            //on mobile, show text below plot
        }

        anno.style("left", x)
            .style("top", y)
            .style("display","block")
            .html("<p>" + d[0].text + "</p>")
            ;
    }
    else{
        anno.style("display","none").html("");
    }
});
    
function tooltip_handler(handler, event, item, value){

    var node = outer_wrap.node();
    var xy = d3.clientPoint(node, event);
    var box = node.getBoundingClientRect();
    
    var widthpct = xy[0]/(box.right-box.left);

    if(value != null){
        tooltip.html('<p>'+value[0]+'</p><p>' + value[1] + '</p>')
               .style("top",Math.round(xy[1] - 15)+"px")
               .style("display","block");

        tooltip.style("left", widthpct <= .50 ? Math.round(xy[0] + 10) + "px" : Math.round(xy[0] - 10 - tip_width) + "px");
    }
    else{
        tooltip.html("");
        tooltip.style("display","none");
    }      
}

return {vega_view: view, title:title};

}









