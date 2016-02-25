_ = require 'underscore'
$ = require 'jquery'
CallbackCounter = require './CallbackCounter'
util = require './util'

COLORS = [
  '#FFB300'  # Vivid Yellow
  '#803E75'  # Strong Purple
  '#C10020'  # Vivid Red
  '#007D34'  # Vivid Green
  '#F6768E'
  '#00538A'  # Strong Blue
  '#FF7A5C'  # Strong Yellowish Pink
  '#53377A'  # Strong Violet
  '#FF8E00'  # Vivid Orange Yellow
  '#B32851'  # Strong Purplish Red
  '#F4C800'  # Vivid Greenish Yellow
  '#7F180D'  # Strong Reddish Brown
  '#93AA00'  # Vivid Yellowish Green
  '#593315'  # Deep Yellowish Brown
  '#F13A13'  # Vivid Reddish Orange
  '#232C16'  # Dark Olive Green
  '#817066'  # Medium Gray
  '#FF6800'  # Vivid Orange
  '#CEA262'  # Grayish Yellow
]


createMapFromSearchString = (elemId, search) ->
  paths = search.replace(/^\?/, '').split('&')
  console.log 'paths:', paths
  map = new MapWrapper(document.getElementById(elemId))
  for path, i in paths
    color = COLORS[i]
    map.getAndAddPath(color, util.getUrl("#{path}.json"))
  map.done()

class MapWrapper
  constructor: (elem) ->
    @map = new google.maps.Map(elem, mapTypeId: google.maps.MapTypeId.TERRAIN)
    @infowindow = new google.maps.InfoWindow()
    @ne = lng: -180, lat: -90
    @sw = lng:  180, lat:  90
    @legend = []
    @info = '' # remember last info for title when only one track
    @counter = new CallbackCounter(1, () => @_finish())

  # the NE and SW corners of a rectangle enclosing all of the paths
  getBounds: () -> ne: @ne, sw: @sw

  done: () -> @counter.decr()

  # once we have bounds from all the paths, fit map to them
  _finish: () ->
    document.title = @legend[0].name
    @map.fitBounds(new google.maps.LatLngBounds(@sw, @ne))
    title =
      if @legend.length == 1
        "<div id='title'>#{@info}</div>"
      else
        tracks = _.sortBy(@legend, (x) -> x.date)
        tracks.reverse()
        title = (
          for t in tracks
            """
              <tr>
                <td><span class='hline' style='background-color: #{t.color}'></span></td>
                <td>#{t.Date.replace(/ \d+:\d+ [ap]m/, '')}</td>
                <td>&ndash; #{t.name}</td>
              </tr>
            """
        ).join('')
        "<table id='title'>#{title}</table>"
    @map.controls[google.maps.ControlPosition.TOP_CENTER].push($(title)[0])

  _titleHtml: () ->
    if @legend.length == 1
      "<div id='title'>#{@info}</div>"
    else
      tracks = _.sortBy(@legend, (x) -> x.date)
      tracks.reverse()
      "<table id='title'>#{
        (
          for t in tracks
            "<tr>
              <td><span class='hline' style='background-color: #{t.color}'></span></td>
              <td>#{t.Date}</td>
              <td>&ndash; #{t.name}</td>
            </tr>"
        ).join('')
      }</table>"

  getAndAddPath: (color, url) ->
    @counter.incr()
    $.ajax
      url:     url
      type:    'GET'
      success: (data)  => @addPath(color, data)
      error:   (error) => console.log 'error', error

  # add a path to the map in this color, update bounds
  addPath: (color, data) ->
    @legend.push(name: data.name, date: data.date, Date: data.Date, color: color)
    path = data.coords
    if not path? || path.length == 0
      console.log 'bad data:', data
      return
    if data.omit
      path.length -= data.omit
    start = path[0]
    end = path[path.length-1]
    polyline = new google.maps.Polyline
      path:          path
      geodesic:      true
      strokeColor:   color
      strokeOpacity: 1.0
      strokeWeight:  3
    polyline.setMap(@map)

    distance = @_computeDistance(polyline)
    @info = """
      <h2>#{data.name}</h2>
      #{data.Date}<br>
      Distance: #{distance}<br>
      Altitude: #{data['Min Altitude']} - #{data['Max Altitude']}
    """
    @addMarker(end, 'End', @info)
    @addMarker(start, 'Start', @info)

    for point in path
      {lat, lng} = point
      if lat < @sw.lat then @sw.lat = lat
      if lat > @ne.lat then @ne.lat = lat
      if lng < @sw.lng then @sw.lng = lng
      if lng > @ne.lng then @ne.lng = lng
    @counter.decr()

  addMarker: (position, title, content) ->
    marker = new google.maps.Marker(map: @map, position: position, title: title)
    google.maps.event.addListener marker, 'click', () =>
      @infowindow.close()
      @infowindow.setContent(content)
      @infowindow.open(@map, marker)

  _computeDistance: (polyline) ->
    lenMeters = google.maps.geometry.spherical.computeLength(polyline.getPath().getArray())
    return (lenMeters/1609.34).toFixed(2)  # convert to miles

if not window.tsk? then window.tsk = {}
window.tsk.MapWrapper = MapWrapper
window.tsk.createMapFromSearchString = createMapFromSearchString
