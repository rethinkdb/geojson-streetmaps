BROWSERIFY=node_modules/.bin/browserify
RDBHOST?=localhost
RDBPORT?=28015
DB?=geojson_streetmaps
STREETS=streets
POIS=points_of_interest
RQL=rql --host=$(RDBHOST) --port=$(RDBPORT) --db=$(DB)

all: import static/bundle.js

pip: requirements.txt
	pip install -r requirements.txt

${BROWSERIFY}:
	npm install .

static/bundle.js: static/app.coffee $(BROWSERIFY)
	$(BROWSERIFY) --transform=coffeeify static/app.coffee -o static/bundle.js

import: pip
	rethinkdb-import -c $(RDBHOST):$(RDBPORT) --table $(DB).$(STREETS) -f streets.json
	$(RQL) "r.table('$(STREETS)').index_create('geometry', geo=True)"
	rethinkdb-import -c $(RDBHOST):$(RDBPORT) --table $(DB).$(POIS) -f points-of-interest.json
	$(RQL) "r.table('$(POIS)').index_create('geometry', geo=True)"
	$(RQL) "r.table('$(STREETS)').index_wait('geometry')"
	$(RQL) "r.table('$(POIS)').index_wait('geometry')"
