import argparse
import json
from datetime import datetime
from itertools import islice

import rethinkdb as r
import tornado.web
from more_itertools import chunked


class RethinkDBHandler(tornado.web.RequestHandler):
    def initialize(self):
        self.conn = r.connect(self.application.settings['host'],
                              self.application.settings['port'],
                              db=self.application.settings['db'])


class PointOfInterestHandler(RethinkDBHandler):
    def get(self, *args):
        self.set_header('Content-Type', 'application/json')
        center = r.point(*map(float, args))
        selection = r.table('points_of_interest').get_nearest(
            center, index='geometry', max_results=20, unit='mi')
        start_t = datetime.now()
        array = selection.map(lambda row: {
            'type': 'Feature',
            'geometry': row['doc']['geometry'].to_geojson(),
            'properties': row['doc']['properties'].merge(
                {'distance': row['dist']}),
        }).run(self.conn)
        total_t = (datetime.now() - start_t).total_seconds()
        print 'POI query took', total_t, 's and provided', len(array), 'results'
        self.write(json.dumps(array))


class OSMHandler(RethinkDBHandler):

    def write_event(self, data):
        self.write('data: {}\n\n'.format(json.dumps(data)))
        self.flush()

    def get(self, *args):
        self.set_header('Content-Type', 'text/event-stream')
        north, south, east, west = map(float, args)
        start_t = datetime.now()
        query_range = r.polygon(
            r.point(north, west),
            r.point(south, west),
            r.point(south, east),
            r.point(north, east))
        selection = (r.table('streets')
                     .get_intersecting(query_range, index='geometry'))
        initial_t = (datetime.now() - start_t).total_seconds()
        cursor = selection.map(r.row['geometry'].to_geojson()).run(self.conn)
        size = 0
        for chunk in chunked(cursor, 2000):
            size += len(chunk)
            self.write_event(chunk)
        self.write_event('done')
        total_t = (datetime.now() - start_t).total_seconds()
        print 'street query took', initial_t, 's for the first batch',
        print '(', total_t, 's total) and provided', size, 'results.'


def main(port, host, rport, db):
    settings = {'host': host, 'port': rport, 'db': db}
    routes = [
        (r'/osm/(.*?)/(.*?)/(.*?)/(.*?)/?', OSMHandler),
        (r'/poi/(.*?)/(.*?)/?', PointOfInterestHandler),
        (r'/()$', tornado.web.StaticFileHandler,
         {'path': 'static/index.html'}),
        (r'/(.+)', tornado.web.StaticFileHandler, {'path': 'static'}),
    ]
    tornado.web.Application(routes, **settings).listen(port)
    tornado.ioloop.IOLoop.instance().start()

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('port', type=int, default=8090,
                        help='Port server should run on')
    parser.add_argument('--rhost', default='localhost',
                        help='RethinkDB hostname to connect to')
    parser.add_argument('--rport', type=int, default=28015,
                        help='RethinkDB port to connect to')
    parser.add_argument('--db', '-d', default='geojson_streetmaps',
                        help='Database to use (default: geojson_streetmaps)')
    args = parser.parse_args()
    main(args.port, args.rhost, args.rport, args.db)


