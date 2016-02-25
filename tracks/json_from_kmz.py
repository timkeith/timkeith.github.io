#!/usr/bin/env python
import collections
import json
from glob import glob
import re
import os
import xml.etree.ElementTree as ElementTree
import dateutil.parser
from zipfile import ZipFile, BadZipfile

def main():
  info_json = get_json('info.json')
  all_info = map(lambda dir: do_dir(dir, info_json[dir]), info_json)
  put_json('main.json', all_info)

def do_dir(dir, extra):
  dir_info = [ do_file(kmz_path, extra) for kmz_path in glob('%s/*.kmz' % dir) ]
  return { 'dir': dir, 'name': extra['name'], 'data': sorted(dir_info, key=lambda x: x['date']) }

def do_file(kmz_path, extra):
  info = get_info_from_kmz(kmz_path)
  json_path = sub(kmz_path, { r' +': '_', r'/ +': '/', r' *\.kmz$': '.json' })
  base = os.path.basename(json_path)
  if base in extra:
    info = dict(info.items() + extra[base].items())
  put_json(json_path, info)
  return dict(
    { key: info[key] for key in ['date', 'name', 'Distance', 'StartCoord', 'snippet'] },
    path=json_path)

def get_info_from_kmz(kmz):
  print 'kmz:', kmz
  try:
    kml = ZipFile(kmz, 'r').read('doc.kml')
    ns = '{http://earth.google.com/kml/2.2}'
    # the Placemark containing Snippet has the info we want
    placemark = ElementTree.fromstring(kml).find('.//{0}Snippet/..'.format(ns))
    coordinates = list(extract_coordinates(
      placemark.find('./{0}MultiGeometry/{0}LineString/{0}coordinates'.format(ns)).text))
    info = dict((re.sub(r':$', '', tr[0].text), tr[1].text)
        for tr in placemark.find(ns + 'description').iter(ns + 'tr'))
    start = dateutil.parser.parse(info['Start Time'])
    return dict(
      info,
      name=placemark.find(ns + 'name').text,
      snippet=re.sub(r'.*? [ap]m\b ?', '', placemark.find(ns + 'Snippet').text),
      date=str(start.date()),
      time=str(start.time()),
      coords=coordinates,
      StartCoord=coordinates[0],
    )
  except BadZipfile as e:
    print 'Error reading "{0}": {1}'.format(kmz, e)

# Extract the "<lat>,<lng>" coordinates from text, skipping duplicates.
def extract_coordinates(text):
  prev = { 'lng': 0, 'lat': 0 }
  for match in re.compile(r'([-.\d]+),([-.\d]+),').finditer(text):
    c = { 'lng': float(match.group(1)), 'lat': float(match.group(2)) }
    if c != prev:
      prev = c
      yield c

def get_json(path):
  with open('info.json') as data_file:    
    return json.load(data_file)

# Write data as json to path. It is pretty-printed with lat/lng done compactly.
def put_json(path, data):
  with open(path, 'w') as outfile:
    outfile.write(re.sub(
      r'{\s*("lat": *\S+),\s*("lng": *\S+)\s*}', r'{ \1, \2 }',
      json.dumps(data, indent=1, sort_keys=True)))

# Substitute key -> value from subs in string
def sub(string, subs):
  assert isinstance(subs, collections.Mapping), 'Expected dict, got: {0}'.format(subs)
  for key, value in subs.items():
    string = re.sub(key, value, string)
  return string

main()
