# from json_from_kmz.pl
import json
from pprint import pprint
from glob import glob
import re
import os

#if True:
#  print glob('*.json')
#  exit()


def main():
  with open('info.json') as data_file:    
    info_json = json.load(data_file)
  x = [ do_dir(dir, info_json[dir]) for dir in info_json ]
  print 'x:', x
#for dir in info_json:
#  print dir
#  extra = info_json[dir]
#  push(@$all_info, { dir => $dir, name => $extra->{name}, data => do_dir($dir, $extra) });

def do_dir(dir, extra):
  #for kmz in glob(dir + '/*.kmz'):
  for kmz in glob('%s/*.kmz' % dir):
    info = get_info_from_kmz(kmz)
    json = re.sub(r' +', '_', re.sub(r'/ +', '/', re.sub(r' *\.kmz$', '.json', kmz)))
    base = os.path.basename(json)
    if base in extra:
      e = extra[base]
      for key in e.keys():
        info[key] = e[key]
    #put_json($json, $info);
    #push(@$dir_info,
    #  { path => $json, map { $_ => $info->{$_} } qw(date name Distance StartCoord snippet) });
  return dir
  #return [ sort { $b->{date} cmp $a->{date} } @$dir_info ];

from zipfile import ZipFile, BadZipfile
import gzip
def get_info_from_kmz(kmz):
  try:
    archive = ZipFile(kmz, 'r')
    kml = archive.read('doc.kml')
    info = {}
    for placemark in re.compile(r'<Placemark>(.*?)</Placemark>').finditer(kml):
      x = placemark.group(1)
      match = re.match(r'<Snippet>(.*?)</Snippet>', x)
      if match:
        print 'kml:', kml
        exit()
        info['snippet'] = re.sub(r'.*? [ap]m\b ?', '', match.group(1))

  except BadZipfile as e:
    print 'Error reading "{0}": {1}'.format(kmz, e)

  #with zipfile.open(kmz, 'r') as fin:
  #  for line in fin:
  #    print('got line', line)
  #x = ZipFile(kmz, 'r')
  #print 'x:', x
  return {}

#  my %info = ();
#  while ($xml =~ m{<Placemark>(.*?)</Placemark>}gs) {
#    my $x = $1;
#    if ($x =~ m{<Snippet>(.*?)</Snippet>}) {
#      $info{snippet} = Misc::subst($1, '.*? [ap]m\b ?' => '');
#      if ($x =~ m{<name>(.*?)</name>}) {
#        $info{name} = $1;
#      }
#      while ($x =~ m{<tr>\s*<td[^<>]*>(.*?):?</td>\s*<td[^<>]*>(.*?)</td>}gs) {
#        my($key, $value) = ($1, $2);
#        $info{$key} = $value;
#      }
#    }
#    if (my $date = $info{Date}) {
#      if ($date =~ s/^(.*?)  *(\d+:\d+ [ap]m)$//) {
#        $info{Date} = $1;
#        $info{Time} = $2;
#      }
#    }
#  }
#  my(undef,undef,undef,$day,$month,$year) = Date::Parse::strptime($info{'Start Time'});
#  $info{date} = sprintf('%04d/%02d/%02d', $year+1900, $month+1, $day);
#
#  my @coordinates = ();
#  if ($xml =~ m{.*<coordinates>\s*(.*?)\s*</coordinates>}s) {
#    my $coordinates = $1;
#    my($lat0, $lng0) = (0, 0);
#    while ($coordinates =~ /([-.\d]+),([-.\d]+),/g) {
#      my($lng, $lat) = ($1, $2);
#      if ($lat ne $lat0 || $lng ne $lng0) {
#        push(@coordinates, { lat => $lat, lng => $lng });
#        $lat0 = $lat;
#        $lng0 = $lng;
#      }
#    }
#    $info{StartCoord} = $coordinates[0];
#  }
#  $info{coords} = \@coordinates;
#  return \%info;

main()
