// CallbackCounter based on https://github.com/tjmehta/callback-count

function CallbackCounter(count, done) { // or function CallbackCounter (done)
  if (typeof count === 'function') {
    done = count;
    count = null;
  }
  this.count = count || 0;
  this.done  = done  || function () {};
  this.results = [];
  this.next = this.next.bind(this);
}

CallbackCounter.prototype.inc = function (inc) {
  this.count += inc === undefined ? 1 : inc;
  return this;
};

CallbackCounter.prototype.next = function (err) { // function (err, results...)
  var results;
  if (this.err) {
    return this; // already errored
  } else if (err) {
    this.err = err;
    this.done(err);
  } else {
    if (this.count > 0) this.count--;
    results = Array.prototype.slice.call(arguments, 1);
    this.results.push(results);
    if (this.count === 0) {
      this.done(null, this.results);
    }
  }
  return this;
};


function getAndAddPath(map, bounds, color, url) {
  $.ajax({
    'url': url, 'type': 'GET',
    'success': function(data) { addPathToMap(map, bounds, color, data.path); },
    'error': function(error) { console.log('error', error); },
  });
}

function addPathToMap(map, bounds, color, coordinates) {
  var start = coordinates[0];
  var end = coordinates[coordinates.length-1];
  var start = new google.maps.Marker({ map: map, position: start, title: 'Start' });
  var end = new google.maps.Marker({ map: map, position: end, title: 'End' });
  var polyline = new google.maps.Polyline({
    path: coordinates,
    geodesic: true,
    strokeColor: color,
    strokeOpacity: 1.0,
    strokeWeight: 2
  });
  polyline.setMap(map);
  // compute bounds
  if (!bounds.ne) {
    bounds = { ne: { lng: -180, lat: -90 }, sw: { lng: 180, lat: 90 } };
  }
  for (var i = 0; i < coordinates.length; i += 1) {
    var lat = coordinates[i].lat;
    var lng = coordinates[i].lng;
    if (lat < bounds.sw.lat) bounds.sw.lat = lat;
    if (lat > bounds.ne.lat) bounds.ne.lat = lat;
    if (lng < bounds.sw.lng) bounds.sw.lng = lng;
    if (lng > bounds.ne.lng) bounds.ne.lng = lng;
  }
  console.log('bounds', JSON.stringify(bounds));
  map.fitBounds(new google.maps.LatLngBounds(bounds.sw, bounds.ne));
  /*
    my $lng = $coord->[0];
    my $lat = $coord->[1];
    $lng0 = $lng if $lng < $lng0;
    $lat0 = $lat if $lat < $lat0;
    $lng1 = $lng if $lng > $lng1;
    $lat1 = $lat if $lat > $lat1;
  }
  return { ne => [$lng1, $lat1], sw => [$lng0, $lat0] };
  */

  // replace length in page title, if there is a #distance node
  /*
  var lenMeters = google.maps.geometry.spherical.computeLength(polyline.getPath().getArray());
  var lenMiles = (lenMeters/1609.34).toFixed(2);
  var distNode = document.getElementById('distance');
  if (distNode) distNode.innerHTML = lenMiles;
  */
}
