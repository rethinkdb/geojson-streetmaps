# RethinkDB streetmaps demo #

This project shows off how geospatial queries can be used to display map data, as well as identify points of interest based on a given location.

First, clone the repository locally:

```bash
$ git clone https://github.com/rethinkdb/geojson-streetmaps.git
```

Next, you'll need to set up a free [Mapbox account][].
This provides the background imagery needed in the demo.

[Mapbox account]: https://www.mapbox.com/plans/

After that, you'll need to install all the dependencies and load the example data. The makefile needs your Mapbox api key to build:

```bash
$ make API_KEY=$API_KEY
```

The make file will:

- install the required nodejs packages
- build the javascript bundle with browserify
- install the server's required python packages
- Create a new database called `geojson_streetmaps`
  - You can configure this with by setting the `$DB` environment variable
- Create two new tables in that database:
  - `streets`, which contains all street geometry excluding points of interest
  - `points_of_interest`, just points of interest data
- Load the two included json files into those tables


Optionally, before you run make you can set a few environment variables to customize where the data gets stored:

```bash
$ export RDBHOST=localhost       # hostname of your RethinkDB server
$ export RDBPORT=28015           # port of your RethinkDB server
$ export DB=geojson_streetmaps   # database to create and import into
```

All of the above are the defaults, customize them as you will.

To run the server do:

```bash
$ python server.py
```

The server process will use the same environment variables as the Makefile, but it also accepts commandline flags:

```
$ python server.py --help
usage: server.py [-h] [--port PORT] [--rdbhost RDBHOST] [--rdbport RDBPORT]
                 [--db DB]

optional arguments:
  -h, --help         show this help message and exit
  --port PORT        Port server should run on
  --rdbhost RDBHOST  RethinkDB hostname to connect to
  --rdbport RDBPORT  RethinkDB port to connect to
  --db DB, -d DB     Database to use (default: geojson_streetmaps)
```

# Data sources and libraries used

The app uses [Mapbox][] for the map imagery.
The points of interest and street/county geometry comes from [OpenStreetMap][]

The frontend uses uses the [leaflet][] library, as well as  [jquery][], to display the geometry on top of the map data.
The backend is built with the [tornado][] web server, and makes use of the  [more-itertools][] library.


[OpenStreetMap]: http://www.openstreetmap.org/#map=5/51.500/-0.100
[Mapbox]: https://www.mapbox.com
[leaflet]: http://leafletjs.com
[jQuery]: http://jquery.com
[tornado]: http://www.tornadoweb.org
[more-itertools]: https://github.com/erikrose/more-itertools
