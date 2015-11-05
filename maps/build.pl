#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename qw(basename);
use File::Spec::Functions qw(catfile catdir);
use lib catfile($ENV{HOME}, 'bin');
use Misc qw(dirname assert note warning error fatal internal);
sub get_info($);

my $template = join('', <DATA>);

my %all = ();
for my $kmz (glob('*.kmz')) {
  my $base = basename($kmz, '.kmz');
  my $base2 = Misc::subst($base, ' ' => '');
  my $h = Misc::subst($template, 'BASE' => $base);
  Misc::put("$base2.html", $h);
  $all{$base2} = get_info($kmz);
}

my $index = <<END;
<!DOCTYPE html>
<html>
<head>
  <style type="text/css">
  </style>
</head>
<body>
END
for my $base (sort keys %all) {
  my %info = %{$all{$base}};
  $index .= "<h2>$info{name}</h2>\n";
  if (my $snippet = $info{snippet}) {
    $index .= "<p>$snippet</p>\n";
  }
  $index .= "<p><a href='$base.html'>map</a></p>\n";
  $index .= "<table>\n";
  for my $key ('Date', 'Distance', 'Min Altitude', 'Max Altitude') {
    $index .= "  <tr><td>$key:</td><td>$info{$key}</td></tr>\n";
  }
  $index .= "</table>\n";
END
}
$index .= <<END;
</body>
</html>
END

Misc::put('index.html', $index);

exit;

sub get_info($) {
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
  }
  return \%info;
}

__END__
<!DOCTYPE html>
<html>
<head>
  <style type="text/css">
    html, body { height: 100%; margin: 0; padding: 0; }
    #map { height: 100%; }
  </style>
</head>
<body>
  <div id='map'></div>
  <script type="text/javascript">
    function initMap() {
      var map = new google.maps.Map(document.getElementById('map'), {
        zoom: 11,
        center: {lat: 45.602, lng: -122.892},
        mapTypeId: google.maps.MapTypeId.TERRAIN,
      });
      console.log('map', map);
      var layer = new google.maps.KmlLayer({
        url: 'http://www.timkeith.tk/maps/BASE.kmz',
        map: map,
      });
      console.log('layer', layer);
    }
  </script>
  <script async defer
    src="https://maps.googleapis.com/maps/api/js?key=AIzaSyCqTgoJzFd5QXVynbHiCNM28pHq9SVhbtw&callback=initMap">
  </script>
</body>
</html>
