#!/usr/bin/env perl
use strict;
use warnings;
use JSON ();
use File::Basename qw(basename);
use File::Spec::Functions qw(catfile catdir);
use Date::Parse ();
use lib catfile($ENV{HOME}, 'bin');
use Misc qw(dirname assert note warning error fatal internal);
sub do_dir($);
sub get_info_from_kmz($);

for my $dir (grep(-d, glob('*'))) {
  do_dir($dir);
}

exit;

sub do_dir($) {
  my($dir) = @_;
  for my $kmz (glob("$dir/*.kmz")) {
    my $info = get_info_from_kmz($kmz);
    #print Misc::image($info); exit;
    my $j = JSON->new->indent->space_after->encode($info);
    $j =~ s/\{\s*"lat": *"(.*?)",\s*"lng":\s*"(.*?)"\s*\}/{"lat": $1, "lng": $2}/g;
    $j =~ s/\{\s*"lng": *"(.*?)",\s*"lat":\s*"(.*?)"\s*\}/{"lat": $2, "lng": $1}/g;
    $j =~ s/^   / /gm;
    $j =~ s/^    /  /gm;
    my $json = Misc::subst($kmz, '\.kmz$' => '.json');
    print "$json\n";
    Misc::put($json, $j);
  }
}

sub get_info_from_kmz($) {
  my($kmz) = @_;
  my $xml = do {
    local $/ = undef;
    my $fh = Misc::do_open('-|', "gunzip < '$kmz'");
    <$fh>;
  };
  my %info = ();
  while ($xml =~ m{<Placemark>(.*?)</Placemark>}gs) {
    my $x = $1;
    if ($x =~ m{<Snippet>(.*?)</Snippet>}) {
      $info{snippet} = Misc::subst($1, '.*? [ap]m\b ?' => '');
      if ($x =~ m{<name>(.*?)</name>}) {
        $info{name} = $1;
      }
      while ($x =~ m{<tr>\s*<td[^<>]*>(.*?):?</td>\s*<td[^<>]*>(.*?)</td>}gs) {
        my($key, $value) = ($1, $2);
        $info{$key} = $value;
      }
    }
    if (my $date = $info{Date}) {
      if ($date =~ s/^(.*?)  *(\d+:\d+ [ap]m)$//) {
        $info{Date} = $1;
        $info{Time} = $2;
      }
    }
  }
  my(undef,undef,undef,$day,$month,$year) = Date::Parse::strptime($info{'Start Time'});
  $info{date} = sprintf('%04d/%02d/%02d', $year+1900, $month+1, $day);

  my @coordinates = ();
  if ($xml =~ m{.*<coordinates>\s*(.*?)\s*</coordinates>}s) {
    my $coordinates = $1;
    my($lat0, $lng0) = (0, 0);
    while ($coordinates =~ /([-.\d]+),([-.\d]+),/g) {
      my($lng, $lat) = ($1, $2);
      if ($lat ne $lat0 || $lng ne $lng0) {
        push(@coordinates, { lat => $lat, lng => $lng });
        $lat0 = $lat;
        $lng0 = $lng;
      }
    }
    $info{StartCoord} = $coordinates[0];
  }
  $info{coords} = \@coordinates;
  #if ($xml =~ m{<coordinates>\s*(.*?),(.*?),}) {
  #  $info{StartCoord} = [$1, $2];
  #}
  return \%info;
}
