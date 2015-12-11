#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename qw(basename);
use File::Spec::Functions qw(catfile catdir);
use Date::Parse ();
use lib catfile($ENV{HOME}, 'bin');
use Misc qw(dirname assert note warning error fatal internal);
sub do_dir($);
sub gen_all_map($$$);
sub get_bounds($);
sub get_info_txt($);
sub gen_contents($$);
sub finish($);
sub gen_page($$$);
sub gen_all_kml($$);
sub get_info_from_kmz($);
sub path_to_url($);
sub t_page_html($$);
sub t_initMap($$$);
sub t_addMarker();
sub t_infowindow_contents($;$);
sub to_point($);
sub gen_polyline_js($$);
sub t_polyline_initMap_body();
sub t_kml_page($);
sub t_map_html($;$);

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
  my %dir_info = get_info_txt($dir);
  for my $html (glob("$dir/*.html")) {
    unlink($html);
  }
  for my $kmz (glob("$dir/*.kmz")) {
    my $base = basename($kmz, '.kmz');
    my $base2 = Misc::subst($base, ' ' => '');
    my $base3 = Misc::subst($base, ' ' => '%20');
    my $url = path_to_url("$dir/$base3.kmz");
    push(@urls, $url);
    my $info = get_info_from_kmz($kmz);
    #$info->{url} = path_to_url("$dir/$base2.html");
    $info->{url} = "/maps/$dir/$base2.html";
    # override $info from info.txt
    while (my($key, $value) = each %dir_info) {
      if ($key =~ /^$base2\.(.+)$/) {
        print "override for $base2: $key=$value\n";
        $info->{$1} = $value;
      }
    }
    $all{$base2} = $info;
    if (0) {
      gen_page("$dir/$base2.html", $info->{name}, t_kml_page($url));
    } else {
      #my $omit = $dir_info{"$base2.omit"} || 0;
      my $omit = $info->{omit} || 0;
      print "$dir/$base2.html - omit last $omit points\n" if $omit;
      my $title = t_infowindow_contents($info, 1);
      gen_page("$dir/$base2.html", $info->{name},
        t_map_html(gen_polyline_js($info->{Coords}, $omit), $title));
    }
    #print "$dir/$base2.html\n";
  }
  my $index_html = "<h2>$dir_info{name}</h2>\n";
  for my $key (sort {$all{$b}->{date} cmp $all{$a}->{date}} keys %all) {
    $index_html .= gen_contents($key, $all{$key});
  }
  gen_all_map("$dir/all.html", $dir_info{name}, \%all);
  #gen_all_kml("$dir/all.kml", \@urls);
  #gen_page("$dir/all.html", $dir_info{name},
  #  Misc::subst($template, '\b_URL_\b' => path_to_url("$dir/all.kml")));
  gen_page("$dir/index.html", $dir_info{name}, $index_html);
  #return "<a href='$dir/index.html'>$dir_info{name}</a>";
  return "<a href='$dir/all.html'>$dir_info{name}</a>";
}

sub gen_all_map($$$) {
  my($outfile, $dir_name, $all) = @_;
  my $body = t_addMarker();
  my @coords = ();
  while (my($base, $info) = each %$all) {
    my $name = Misc::subst($info->{name}, '^\s+' => '', '\s+$' => '');
    my $coord = $info->{StartCoord};
    push(@coords, $coord);
    my $pos = to_point($coord);
    my $content = t_infowindow_contents($info);
    $body .= "addMarker(map, $pos, \"$name\", \"$content\");\n";
  }
  if (@coords > 0) {
    my $bounds = get_bounds(\@coords);
    my $ne = to_point($bounds->{ne});
    my $sw = to_point($bounds->{sw});
    my $initMap = t_initMap($sw, $ne, $body);
    my $html = t_map_html($initMap, "<h2>All $dir_name</h2>");
    Misc::put($outfile, t_page_html("All $dir_name", $html));
  }
}

# Return hash ref with sw and ne representing the corners of the rectangle containing all points
sub get_bounds($) {
  my($coords) = @_;
  my($lng0, $lng1, $lat0, $lat1) = (180, -180, 90, -90);
  for my $coord (@$coords) {
    my $lng = $coord->[0];
    my $lat = $coord->[1];
    $lng0 = $lng if $lng < $lng0;
    $lat0 = $lat if $lat < $lat0;
    $lng1 = $lng if $lng > $lng1;
    $lat1 = $lat if $lat > $lat1;
  }
  return { ne => [$lng1, $lat1], sw => [$lng0, $lat0] };
}

sub get_info_txt($) {
  my($dir) = @_;
  my $txt = Misc::get("$dir/info.txt");
  return $txt =~ /^([^:\n]+): *(.*)/gm;
}

sub gen_contents($$) {
  my($base, $info) = @_;
  my $h = "<b>$info->{name}</b>\n";
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
  #$contents =~ s/^/  /gm;
  $contents =~ s/ +$//gm;
  Misc::put($outfile, t_page_html($title, $contents));
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

  my @coordinates = ();
  if ($xml =~ m{.*<coordinates>\s*(.*?)\s*</coordinates>}s) {
    my $coordinates = $1;
    my @prev = (0, 0);
    while ($coordinates =~ /([-.\d]+),([-.\d]+),/g) {
      my @curr = ($1, $2);
      if ($curr[0] ne $prev[0] || $curr[1] ne $prev[1]) {
        push(@coordinates, \@curr);
        @prev = @curr;
      }
    }
    $info{StartCoord} = $coordinates[0];
  }
  $info{Coords} = \@coordinates;
  #if ($xml =~ m{<coordinates>\s*(.*?),(.*?),}) {
  #  $info{StartCoord} = [$1, $2];
  #}
  return \%info;
}

sub path_to_url($) {
  my($path) = @_;
  return Misc::subst('http://www.timkeith.tk/maps/_PATH_', '_PATH_' => $path);
}

### Code templates

sub t_page_html($$) {
  my($title, $contents) = @_;
  return <<END;
<!DOCTYPE html>
<html>
<head>
  <style type='text/css'>
    body {
      font-family: sans-serif;
    }
  </style>
  <title>$title</title>
</head>
<body>
$contents
</body>
</html>
END
}

# Generate initMap function: $sw and $ne are the bounds, $body is the code that goes in it.
sub t_initMap($$$) {
  my($sw, $ne, $body) = @_;
  $body =~ s/^/    /gm;
  return Misc::subst(qq[
    function initMap() {
      var map = new google.maps.Map(document.getElementById('map'), {
        mapTypeId: google.maps.MapTypeId.TERRAIN,
      });
      map.fitBounds(new google.maps.LatLngBounds($sw, $ne));
      map.controls[google.maps.ControlPosition.TOP_CENTER].push(document.getElementById('title'));
      console.log('map', map);
      $body
    }
  ], '(?m)^    ' => '');
}

sub t_addMarker() {
  return <<END;
var infowindow = new google.maps.InfoWindow();
function addMarker(map, position, title, content) {
  var marker = new google.maps.Marker({ map: map, position: position, title: title });
  google.maps.event.addListener(marker, 'click', function() {
    infowindow.close();
    infowindow.setContent(content);
    infowindow.open(map, marker);
  });
}
END
}

sub t_infowindow_contents($;$) {
  my($info, $noUrl) = @_;
  my $url_line = $noUrl ? '' : "<br>Map: <a target='_blank' href='$info->{url}'>$info->{url}</a>";
  return Misc::subst(<<END, "\n" => ' ');
<h2>$info->{name}</h2>
$info->{Date}<br>
Distance: <span id='distance'>$info->{Distance}</span><br>
Altitude: $info->{'Min Altitude'} - $info->{'Max Altitude'}
$url_line
END
}

sub to_point($) {
  my($coordinates) = @_;
  return "{lng: $coordinates->[0], lat: $coordinates->[1]}";
}

sub gen_polyline_js($$) {
  my($coords, $omit) = @_;
  splice($coords, @$coords - $omit);
  my $bounds = get_bounds($coords);
  my $getCoordinates = "\n\nfunction getCoordinates() { return [\n"
    . join("\n", map { to_point($_) . ',' } @{$coords})
    . "\n] }\n\n";
  return t_initMap(to_point($bounds->{sw}), to_point($bounds->{ne}), t_polyline_initMap_body())
    . $getCoordinates;
}

sub t_polyline_initMap_body() {
  return Misc::subst(qq[
    var coordinates = getCoordinates();
    var start = coordinates[0];
    var end = coordinates[coordinates.length-1];
    var start = new google.maps.Marker({ map: map, position: start, title: 'Start' });
    var end = new google.maps.Marker({ map: map, position: end, title: 'End' });
    var polyline = new google.maps.Polyline({
      path: coordinates,
      geodesic: true,
      strokeColor: '#0000FF',
      strokeOpacity: 1.0,
      strokeWeight: 2
    });
    polyline.setMap(map);
    // replace length in page title, if there is a #distance node
    var lenMeters = google.maps.geometry.spherical.computeLength(polyline.getPath().getArray());
    var lenMiles = (lenMeters/1609.34).toFixed(2);
    var distNode = document.getElementById('distance');
    if (distNode) distNode.innerHTML = lenMiles;
  ], '    ' => '');
}

sub t_kml_page($) {
  my($url) = @_;
  my $js = <<END;
  function initMap() {
    var map = new google.maps.Map(document.getElementById('map'), {
      zoom: 11,
      center: {lat: 45.602, lng: -122.892},
      mapTypeId: google.maps.MapTypeId.TERRAIN,
    });
    console.log('map', map);
    var layer = new google.maps.KmlLayer({
      url: $url,
      map: map,
    });
    console.log('layer', layer);
  }
END
  return t_map_html($js);
}

# html for map page around initMap function
sub t_map_html($;$) {
  my($initMap, $title) = @_;
  $title = '' if !defined $title;
  return <<END;
<style type='text/css'>
  html, body { height: 100%; margin: 0; padding: 0; }
  #map { height: 100%; }
  #title {
    margin-top: .5em;
    font-size: 120%;
    position: absolute;
    background-color: rgba(255, 255, 255, 0.7);
    border: 1px solid black;
    padding: .3em;
  }
  h2 {
    font-size: 125%;
    margin-top: 0;
    margin-bottom: .2em;
  }
</style>
<div id='map'></div>
<div id='title' style='color: black; font-size: 120%; position: absolute;'>
$title
</div>
<script type='text/javascript'>
$initMap
</script>
<script
  src='https://maps.googleapis.com/maps/api/js?libraries=geometry&key=AIzaSyCqTgoJzFd5QXVynbHiCNM28pHq9SVhbtw&callback=initMap'>
</script>
END
}
