# RethinkDB streetmaps demo #

This project shows off how geospatial queries can be used to display map data, as well as identify points of interest based on a given location.

First, clone the repository locally:

```bash
$ git clone https://github.com/rethinkdb/geojson-streetmaps.git
```

Next, you'll need to install the required nodejs packages, build the required static files, install the python packages, and import the map data into your database.

Luckily, all this can be done with `make`:

```bash
$ make
```

Optionally, before you run make you can set a few environment variables to customize where the data gets stored:

```bash
$ export RDBHOST=localhost
$ export RDBPORT=28015
$ export DB=geojson_streetmaps
```

All of the above are the defaults, customize them as you will.

To run the server do:

```bash
$ python server.py
```

The server process will use the same enviroment variables as the Makefile, but it also accepts commandline flags:

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
