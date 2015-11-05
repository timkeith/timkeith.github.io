#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename qw(basename);
use File::Spec::Functions qw(catfile catdir);
use lib catfile($ENV{HOME}, 'bin');
use Misc qw(dirname assert note warning error fatal internal);
sub do_dir($);
sub finish($);
sub gen_page($$$);
sub get_info_from_kmz($);

my $template = join('', <DATA>);

my @links = [];
for my $dir (grep(-d, glob('*'))) {
  push(@links, do_dir($dir));
}
finish(\@links);

exit;

# gen index.html for dir, return <a> elem for it
sub do_dir($) {
  my($dir) = @_;
  my %all = ();
  for my $kmz (glob("$dir/*.kmz")) {
    my $base = basename($kmz, '.kmz');
    my $base2 = Misc::subst($base, ' ' => '');
    my $base3 = Misc::subst($base, ' ' => '%20');
    my $h = Misc::subst($template, 'BASE' => $base3);
    my $info = get_info_from_kmz($kmz);
    $all{$base2} = $info;
    gen_page("$dir/$base2.html", $info->{name}, $h);
    print "$dir/$base2.html\n";
exit;
  }
}


#for my $base (sort keys %all) {
#  my %info = %{$all{$base}};
#  $index .= "<h3>$info{name}</h3>\n";
#  if (my $snippet = $info{snippet}) {
#    $index .= "<p>$snippet</p>\n";
#  }
#  $index .= "<p><a href='$base.html'>map</a></p>\n";
#  $index .= "<table>\n";
#  for my $key ('Date', 'Distance', 'Min Altitude', 'Max Altitude') {
#    $index .= "  <tr><td>$key:</td><td>$info{$key}</td></tr>\n";
#  }
#  $index .= "</table>\n";
#}

sub finish($) {
  my($links) = @_;
  gen_page(
    'index.html', 'Maps',
    "<ul>\n" . join('', map { "  <li>$_</li>\n" } @$links) . "</ul>\n");
}

sub gen_page($$$) {
  my($outfile, $title, $contents) = @_;
  $contents =~ s/^/  /gm;
  my $html = <<END;
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
  Misc::put($outfile, $html);
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
  }
  return \%info;
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
      url: 'http://www.timkeith.tk/maps/BASE.kmz',
      map: map,
    });
    console.log('layer', layer);
  }
</script>
<script
  src="https://maps.googleapis.com/maps/api/js?key=AIzaSyCqTgoJzFd5QXVynbHiCNM28pHq9SVhbtw&callback=initMap">
</script>
