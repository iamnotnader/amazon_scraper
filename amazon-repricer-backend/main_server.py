import os
from urlparse import urlparse
from flask import Flask, request, Response
from functools import wraps
from pymongo import Connection
from werkzeug.security import check_password_hash,generate_password_hash
import json
import requests
from boto.s3.connection import S3Connection
from boto.s3.key import Key
import time
from flask import jsonify
import boto

from datetime import timedelta
from flask import make_response, request, current_app
from functools import update_wrapper


def crossdomain(origin=None, methods=None, headers=None,
                max_age=21600, attach_to_all=True,
                automatic_options=True):
    if methods is not None:
        methods = ', '.join(sorted(x.upper() for x in methods))
    if headers is not None and not isinstance(headers, basestring):
        headers = ', '.join(x.upper() for x in headers)
    if not isinstance(origin, basestring):
        origin = ', '.join(origin)
    if isinstance(max_age, timedelta):
        max_age = max_age.total_seconds()

    def get_methods():
        if methods is not None:
            return methods

        options_resp = current_app.make_default_options_response()
        return options_resp.headers['allow']

    def decorator(f):
        def wrapped_function(*args, **kwargs):
            if automatic_options and request.method == 'OPTIONS':
                resp = current_app.make_default_options_response()
            else:
                resp = make_response(f(*args, **kwargs))
            if not attach_to_all and request.method != 'OPTIONS':
                return resp

            h = resp.headers
            h['Access-Control-Allow-Origin'] = origin
            h['Access-Control-Allow-Methods'] = get_methods()
            h['Access-Control-Max-Age'] = str(max_age)
            h['Access-Control-Allow-Credentials'] = 'true'
            h['Access-Control-Allow-Headers'] = \
                "Origin, X-Requested-With, Content-Type, Accept, Authorization"
            if headers is not None:
                h['Access-Control-Allow-Headers'] = headers
            return resp

        f.provide_automatic_options = False
        return update_wrapper(wrapped_function, f)
    return decorator

requests = requests.session()

MONGO_URL = os.environ.get('MONGOHQ_URL')

if MONGO_URL:
  print 'FOUND_MONGO'
  # Get a connection
  connection = Connection(MONGO_URL)
  # Get the database
  db = connection[urlparse(MONGO_URL).path[1:]]
else:
  print 'NO_MONGO'
  # Not on an app with the MongoHQ add-on, do some localhost action
  connection = Connection('localhost', 27017)
  db = connection['MyDB']

db.amazon_scrape_results.ensure_index( "manufacturerName", unique=True, dropDups=True, sparse=True )

app = Flask(__name__)
app.debug = True

@app.route('/create_results', methods=['POST'])
@crossdomain(origin="*")
def create_results():
    dict_input = json.loads(request.form['json_str'])
    db.amazon_scrape_results.save(dict(dict_input))
    print dict_input['min_prices']

    """
    # Don't add manufacturers upon result creation.
    manufacturers = [{'manufacturerName': result['manufacturer']} for result in dict(dict_input)['results']]

    db.amazon_scrape_results.insert(manufacturers, continue_on_error=True)
    """

    return json.dumps(dict_input)

@app.route('/update_form_fields/<name>', methods=['POST'])
@crossdomain(origin="*")
def update_battery_prices(name):
    print name
    dict_input = json.loads(request.form['json_str'])
    db.amazon_scrape_results.update({'result_set_name': name},
                                    {'$set': {'min_prices': dict(dict_input)['min_prices'],
                                              'sku_prefix': dict(dict_input)['sku_prefix'],
                                              'discount_percent': dict(dict_input)['discount_percent'],
                                              'minimum_price': dict(dict_input)['minimum_price']}})
    print dict_input['min_prices']
    print dict_input['sku_prefix']
    print dict_input['discount_percent']
    print dict_input['minimum_price']
    return json.dumps(dict_input)

@app.route('/add_listing_to/<name>', methods=['POST'])
@crossdomain(origin="*")
def add_listing_to(name):
    json_dict_input = json.loads(request.form['json_str'])
    dict_input = dict(json_dict_input)
    db.amazon_scrape_results.update({'result_set_name': name},
                                    {'$addToSet': {'listed_items' : dict_input}})

    db.amazon_scrape_results.insert({'manufacturerName':dict_input['manufacturer'], 'manufacturerLink': dict_input['manufacturerLink']}, continue_on_error=True)

    return json.dumps(json_dict_input)

@app.route('/remove_listing_from/<name>', methods=['POST'])
@crossdomain(origin="*")
def remove_listing_from(name):
    json_dict_input = json.loads(request.form['json_str'])
    dict_input = dict(json_dict_input)
    print dict_input

    new_dict = dict(db.amazon_scrape_results.find_one({'result_set_name': name}))
    new_listed_items = new_dict.get('listed_items', [])
    # TODO(nadera): Fix the camelcasing mismatch with batteryType vs. listing_index here..
    new_listed_items = [x for x in new_listed_items if x['listing_index'] != dict_input['listing_index'] or x['batteryType'] != dict_input['battery_type']]

    print new_listed_items
    db.amazon_scrape_results.update({'result_set_name': name},
                                    {'$set': {'listed_items' : new_listed_items}})

    return json.dumps(json_dict_input)

@app.route('/result_set_names', methods=['GET'])
@crossdomain(origin="*")
def result_set_names():
    result_set_names = db.amazon_scrape_results.find(
        {'result_set_name':{'$exists':True}},
        {'result_set_name': 1, '_id': 0})
    return json.dumps([x['result_set_name'] for x in result_set_names])

@app.route('/results_for_name/<name>', methods=['GET'])
@crossdomain(origin="*")
def results_for_name(name):
    print name
    result_set = list(db.amazon_scrape_results.find(
        {'result_set_name':name}, {'_id': 0}))

    if len(result_set) == 0:
        return json.dumps(result_set)

    # Forget about the manufacturers in result set for now.
    manufacturer_ids = {}
    manufacturer_list = db.amazon_scrape_results.find({'manufacturerName': {'$exists': True}})
    for manufacturer in manufacturer_list:
        manufacturer_ids[manufacturer['manufacturerName']] = manufacturer['_id']

    for item in result_set[0].get('listed_items', []):
        item['manufacturer_id'] = str(manufacturer_ids[item['manufacturer']])

    return json.dumps(result_set)

@app.route('/manufacturer_list', methods=['GET'])
@crossdomain(origin="*")
def manufacturer_list():
    manufacturer_list = list(db.amazon_scrape_results.find({'manufacturerName': {'$exists': True}}))
    for x in manufacturer_list:
        x['_id'] = str(x['_id'])

    return json.dumps(manufacturer_list)

@app.route('/listed_items_for_result_set/<name>', methods=['GET'])
@crossdomain(origin="*")
def listed_items_for_result_set(name):
    print name
    result_set = list(db.amazon_scrape_results.find(
        {'result_set_name':name}, {'_id': 0}))

    if len(result_set) == 0:
        return json.dumps(result_set)

    # Forget about the manufacturers in result set for now.
    manufacturer_ids = {}
    manufacturer_list = db.amazon_scrape_results.find({'manufacturerName': {'$exists': True}})
    for manufacturer in manufacturer_list:
        manufacturer_ids[manufacturer['manufacturerName']] = manufacturer['_id']

    results = result_set[0].get('results', [])
    for item in result_set[0].get('listed_items', []):
        item['manufacturer_id'] = str(manufacturer_ids[item['manufacturer']])
        listing_index = item['listing_index']
        item['asin'] = results[listing_index].get('asin', 'NO_ASIN')
        item['rank'] = results[listing_index].get('rank', 'NO_RANK')
        item['price'] = results[listing_index].get('price', 'NO_PRICE')

    result_set[0]['results'] = []

    return json.dumps(result_set)

@app.route('/')
def main_server():
    print 'HELLO'
    return 'FUCK ME!'

if __name__ == '__main__':
  # Bind to PORT if defined, otherwise default to 5000.
  port = int(os.environ.get('PORT', 5000))
  app.run(host='0.0.0.0', port=port)
