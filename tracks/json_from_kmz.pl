#!/usr/bin/env perl
use strict;
use warnings;
use JSON ();
use File::Basename qw(basename);
use File::Spec::Functions qw(catfile catdir);
use Date::Parse ();
use lib catfile($ENV{HOME}, 'bin');
use Misc qw(dirname assert note warning error fatal internal);
sub do_dir($$);
sub get_info_from_kmz($);
sub encode_json($);
sub decode_json($);

my $all_info = [];
my $info_json = decode_json(Misc::get('info.json'));
for my $dir (sort keys %$info_json) {
  my $extra = $info_json->{$dir};
  push(@$all_info, { dir => $dir, name => $extra->{name}, data => do_dir($dir, $extra) });
}
print "main.json\n";
Misc::put('main.json', encode_json($all_info));
exit;

#my $all_info = [];
#for my $dir (grep(-d, sort(glob('*')))) {
#  my $dir_info = do_dir($dir);
#  if (defined($dir_info)) {
#    push(@$all_info, { dir => $dir, data => $dir_info });
#  }
#}
#print "main.json\n";
#Misc::put('main.json', encode_json($all_info));

exit;

sub do_dir($$) {
  my($dir, $extra) = @_;
  my $dir_info = [];
  my @kmzs = glob("$dir/*.kmz");
  return undef unless @kmzs;
  for my $kmz (@kmzs) {
    my $info = get_info_from_kmz($kmz);
    my $json = Misc::subst($kmz, ' *\.kmz$' => '.json', '/ ' => '/', ' +' => '_');
    print "$json\n";
    if (defined(my $e = $extra->{basename($json)})) {
      for my $key (keys %$e) {
        $info->{$key} = $e->{$key};
      }
    }
    Misc::put($json, encode_json($info));
    push(@$dir_info,
      { path => $json, map { $_ => $info->{$_} } qw(date name Distance StartCoord snippet) });
  }
  return [ sort { $b->{date} cmp $a->{date} } @$dir_info ];
  #return $dir_info;
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
  return \%info;
}

sub encode_json($) {
  my($data) = @_;
  my $j = JSON->new->indent->space_after->encode($data);
  $j =~ s/\{\s*"lat": *"(.*?)",\s*"lng":\s*"(.*?)"\s*\}/{"lat": $1, "lng": $2}/g;
  $j =~ s/\{\s*"lng": *"(.*?)",\s*"lat":\s*"(.*?)"\s*\}/{"lat": $2, "lng": $1}/g;
  $j =~ s/^   / /gm;
  $j =~ s/^    /  /gm;
  return $j;
}

sub decode_json($) {
  my($json) = @_;
  return JSON->new->decode($json);
}
