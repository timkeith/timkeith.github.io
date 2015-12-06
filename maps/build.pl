#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename qw(basename);
use File::Spec::Functions qw(catfile catdir);
use Date::Parse ();
use lib catfile($ENV{HOME}, 'bin');
use Misc qw(dirname assert note warning error fatal internal);
sub do_dir($);
sub gen_all_map($$);
sub get_info_txt($);
sub gen_contents($$);
sub finish($);
sub gen_page($$$);
sub gen_all_kml($$);
sub get_info_from_kmz($);
sub path_to_url($);
sub gen_html($$);
sub gen_initMap($$$$$);
sub gen_map_html($);

my $template = join('', <DATA>);

my @links = ();
for my $dir (grep(-d, glob('*'))) {
  push(@links, do_dir($dir));
}
finish(\@links);

exit;

# gen index.html for dir, return <a> elem for it
sub do_dir($) {
  my($dir) = @_;
  my %all = ();
  my @urls = ();
  for my $kmz (glob("$dir/*.kmz")) {
    my $base = basename($kmz, '.kmz');
    my $base2 = Misc::subst($base, ' ' => '');
    my $base3 = Misc::subst($base, ' ' => '%20');
    my $url = path_to_url("$dir/$base3.kmz");
    push(@urls, $url);
    my $h = Misc::subst($template, '\b_URL_\b' => $url);
    my $info = get_info_from_kmz($kmz);
    $info->{url} = path_to_url("$dir/$base2.html");
    $all{$base2} = $info;
    gen_page("$dir/$base2.html", $info->{name}, $h);
    print "$dir/$base2.html\n";
  }
  my %info = get_info_txt($dir);
  my $index_html = "<h2>$info{name}</h2>\n";
  for my $key (sort {$all{$b}->{date} cmp $all{$a}->{date}} keys %all) {
    $index_html .= gen_contents($key, $all{$key});
  }
  gen_all_map("$dir/all.html", \%all);
  #gen_all_kml("$dir/all.kml", \@urls);
  #gen_page("$dir/all.html", $info{name},
  #  Misc::subst($template, '\b_URL_\b' => path_to_url("$dir/all.kml")));
  gen_page("$dir/index.html", $info{name}, $index_html);
  #return "<a href='$dir/index.html'>$info{name}</a>";
  return "<a href='$dir/all.html'>$info{name}</a>";
}

sub gen_all_map($$) {
  my($outfile, $all) = @_;
  my $body = <<END;
function addMarker(map, position, title, content) {
  var m = new google.maps.Marker({ map: map, position: position, title: title });
  m.addListener('click', function() {
    var iw = new google.maps.InfoWindow({ content: '<b>' + title + '</b>' + content });
    iw.open(map, m);
  });
}
END
  my $center = undef;
  my($lng0, $lng1, $lat0, $lat1) = (180, -180, 90, -90);
  while (my($base, $info) = each %$all) {
    my $name = Misc::subst($info->{name}, '^\s+' => '', '\s+$' => '');
    my $coord = $info->{StartCoord};
    my $lng = $coord->[0];
    my $lat = $coord->[1];
    $lng0 = $lng if $lng < $lng0;
    $lat0 = $lat if $lat < $lat0;
    $lng1 = $lng if $lng > $lng1;
    $lat1 = $lat if $lat > $lat1;
    my $pos = "{ lng: $lng, lat: $lat }";
    $center = $pos unless defined $center;
    my $content = Misc::subst(<<END, "\n" => ' ');
<br>$info->{Date}
<br>Distance: $info->{Distance}
<br>Altitude: $info->{'Min Altitude'} - $info->{'Max Altitude'}
<br>Map: <a href='$info->{url}'>$info->{url}</a>
END
    $body .= "addMarker(map, $pos, \"$name\", \"$content\");\n";
  }
  if (defined $center) {
    my $ne = "{ lng: $lng1, lat: $lat1 }";
    my $sw = "{ lng: $lng0, lat: $lat0 }";
    my $initMap = gen_initMap(7, $center, $sw, $ne, $body);
    my $html = gen_map_html($initMap);
    Misc::put($outfile, gen_html("All ???", $html));
  }
}

sub get_info_txt($) {
  my($dir) = @_;
  my $txt = Misc::get("$dir/info.txt");
  return $txt =~ /^(\S+): *(.*)/gm;
}

sub gen_contents($$) {
  my($base, $info) = @_;
  my $h = "<h3>$info->{name}</h3>\n";
  if (my $snippet = $info->{snippet}) {
    $h .= "<p>$snippet</p>\n";
  }
  $h .= "<div><a href='$base.html'>map</a></div>\n";
  $h .= "<table>\n";
  for my $key ('Date', 'Time', 'Distance', 'Min Altitude', 'Max Altitude') {
    $h .= "  <tr><td>$key:</td><td>$info->{$key}</td></tr>\n";
  }
  $h .= "</table>\n";
  return $h;
}

sub finish($) {
  my($links) = @_;
  gen_page(
    'index.html', 'Maps',
    "<h2>Maps</h2>\n<ul>\n" . join('', map { "  <li>$_</li>\n" } @$links) . "</ul>\n");
}

sub gen_page($$$) {
  my($outfile, $title, $contents) = @_;
  $contents =~ s/^/  /gm;
  Misc::put($outfile, gen_html($title, $contents));
}

sub gen_all_kml($$) {
  my($file, $urls) = @_;
  my $kml = <<END;
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Folder>
    <name>Network Links</name>
    <visibility>0</visibility>
    <open>0</open>
    <description>All</description>
END
  for my $url (@$urls) {
    $kml .= <<END;
    <NetworkLink>
      <name>Name</name>
      <visibility>0</visibility>
      <open>0</open>
      <description>Description</description>
      <refreshVisibility>0</refreshVisibility>
      <flyToView>0</flyToView>
      <Link>
        <href>$url</href>
      </Link>
    </NetworkLink>
END
  }
  $kml .= <<END;
  </Folder>
</kml>
END
  Misc::put($file, $kml);
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
  if ($xml =~ m{<coordinates>\s*(.*?),(.*?),}) {
    $info{StartCoord} = [$1, $2];
  }
  return \%info;
}

sub path_to_url($) {
  my($path) = @_;
  return Misc::subst('http://www.timkeith.tk/maps/_PATH_', '_PATH_' => $path);
}

sub gen_html($$) {
  my($title, $contents) = @_;
  return <<END;
<!DOCTYPE html>
<html>
<head>
  <style type='text/css'>
  </style>
  <title>$title</title>
</head>
<body>
$contents
</body>
</html>
END
}

sub gen_initMap($$$$$) {
  my($zoom, $center, $sw, $ne, $body) = @_;
  $body =~ s/^/    /gm;
  return <<END;
  function initMap() {
    var map = new google.maps.Map(document.getElementById('map'), {
      zoom: $zoom,
      center: $center,
      mapTypeId: google.maps.MapTypeId.TERRAIN,
    });
    map.fitBounds(new google.maps.LatLngBounds($sw, $ne));
    console.log('map', map);
$body
  }
END
}

# Gen html for map page around initMap function
sub gen_map_html($) {
  my($initMap) = @_;
  return <<END;
<style type='text/css'>
  html, body { height: 100%; margin: 0; padding: 0; }
  #map { height: 100%; }
</style>
<div id='map'></div>
<script type='text/javascript'>
$initMap
</script>
<script
  src='https://maps.googleapis.com/maps/api/js?key=AIzaSyCqTgoJzFd5QXVynbHiCNM28pHq9SVhbtw&callback=initMap'>
</script>
END
}

__END__
<style type="text/css">
  html, body { height: 100%; margin: 0; padding: 0; }
  #map { height: 100%; }
</style>
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
      url: '_URL_',
      map: map,
    });
    console.log('layer', layer);
  }
</script>
<script
  src="https://maps.googleapis.com/maps/api/js?key=AIzaSyCqTgoJzFd5QXVynbHiCNM28pHq9SVhbtw&callback=initMap">
</script>
