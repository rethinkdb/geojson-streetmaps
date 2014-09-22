L = require 'leaflet'
$ = require 'jquery'
mapboxapikey = require './mapboxapikey.js'

# Leaflet needs to know where its icons are
L.Icon.Default.imagePath = 'node_modules/leaflet/dist/images/'

# Create a map centered on RethinkDB offices
map = L.map('map').setView [37.3873, -122.0663], 16

# Tile-based map
L.tileLayer('https://{s}.tiles.mapbox.com/v3/{id}/{z}/{x}/{y}.png',
    maxZoom: 18
    attribution: 'RethinkDB map demo 
        | Map data &copy;
        <a href="http://openstreetmap.org">OpenStreetMap</a>,
        background imagery &copy;
        <a href="http://mapbox.com">Mapbox</a>'
    id: mapboxapikey.key
).addTo(map);

#  Overlays
myStyle = (g) ->
    switch g.geometry.type
        when 'Polygon' then color: "#ffa080", opacity: 0.01, weight: 4
        when 'LineString' then color: "#0000ff", opacity: 0.2
        
streetLayer = L.geoJson([], style: myStyle).addTo map
streetLayer.on "contextmenu", updatePOIs
poisLayer = L.geoJson().addTo map

# Refresh overlay whenever the map is redrawn
updateStreetsId = 0
updateStreets = (e) -> 
    updateStreetsId++
    streetLayer.clearLayers()
    if map.getZoom() >= 15
        ((_updateId) ->
            # Load new data
            bounds = map.getBounds()
            [north, south] = [bounds.getNorth(), bounds.getSouth()]
            [east, west] = [bounds.getEast(), bounds.getWest()]
            jsonStream = new EventSource("/osm/#{north}/#{south}/#{east}/#{west}")
            jsonStream.onmessage = (e) ->
                if e.data == '"done"' or updateStreetsId != _updateId
                    jsonStream.close()
                else
                    json = JSON.parse(e.data)
                    streetLayer.addData(json)
      )(updateStreetsId);

map.on "load", updateStreets
map.on "moveend", updateStreets
map.on "zoomend", updateStreets

updateStreets()

# Gets POIs
onEachFeature = (feature, layer) ->
    if feature.properties
        popupContent = "<p><b>#{feature.properties.name}</b><br>
            Distance: #{Math.round(feature.properties.distance*10)/10} mi
            mi</p>"
        layer.bindPopup popupContent

updatePOIsId = 0

centerOverlay = null

updatePOIs = (e) ->
    if centerOverlay
        map.removeLayer centerOverlay
    centerOverlay = L.circleMarker [e.latlng.lat, e.latlng.lng],
        fillColor: "#ff0000"
        fillOpacity: 1
        color: "#ff0000"
        weight: 5
    .addTo map

    updatePOIsId++;
    ((_updateId) ->
        # Load new data
        $.getJSON("/poi/#{e.latlng.lng}/#{e.latlng.lat}", (json) ->
            if updatePOIsId == _updateId
                myStyle = color: "#40f040", opacity: 0.5
                newPoisLayer = L.geoJson json,
                    style: myStyle
                    onEachFeature: onEachFeature
                # Swap the layers
                map.removeLayer poisLayer
                poisLayer = newPoisLayer
                poisLayer.addTo map
      ))(updatePOIsId);
map.on "contextmenu", updatePOIs
