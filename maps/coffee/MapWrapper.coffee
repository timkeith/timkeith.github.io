class MapWrapper
  #constructor: (@map) ->
  #  @ne = lng: -180, lat: -90
  #  @sw = lng:  180, lat:  90
  #  @counter = new CallbackCounter(1, () => @fitBounds())
  constructor: (elem) ->
    @map = new google.maps.Map(elem, mapTypeId: google.maps.MapTypeId.TERRAIN)
    @ne = lng: -180, lat: -90
    @sw = lng:  180, lat:  90
    @legend = []
    @counter = new CallbackCounter(1, () => @_finish())
    @title = ''  # set this to html string change title

  # the NE and SW corners of a rectangle enclosing all of the paths
  getBounds: () -> ne: @ne, sw: @sw

  done: () -> @counter.decr()

  # once we have bounds from all the paths, fit map to them
  _finish: () ->
    @map.fitBounds(new google.maps.LatLngBounds(@sw, @ne))
    # generate title if needed
    if @title == ''
      for x in @legend
        span = "<span class='hline' style='background-color: #{x.color}'></span>"
        @title += "<div>#{span} #{x.date} #{x.name}</div>"
    elem = $("<div id='title'>#{@title}</div>")
    @map.controls[google.maps.ControlPosition.TOP_CENTER].push(elem[0])

  getAndAddPath: (color, url) ->
    @counter.incr()
    $.ajax
      url:     url
      type:    'GET'
      success: (data) => @addPath(color, data)
      error:   (error) -> console.log 'error', error

  # add a path to the map in this color, update bounds
  addPath: (color, data) ->
    @legend.push(name: data.name, date: data.date, color: color)
    path = data.coords
    if not path? || path.length == 0
      console.log 'Bad data: missing "coords" property:', data
      return
    start = path[0]
    end = path[path.length-1]
    start = new google.maps.Marker(map: @map, position: start, title: 'Start')
    end = new google.maps.Marker(map: @map, position: end, title: 'End')
    polyline = new google.maps.Polyline
      path:          path
      geodesic:      true
      strokeColor:   color
      strokeOpacity: 1.0
      strokeWeight:  2
    polyline.setMap(@map)
    for point in path
      {lat, lng} = point
      if lat < @sw.lat then @sw.lat = lat
      if lat > @ne.lat then @ne.lat = lat
      if lng < @sw.lng then @sw.lng = lng
      if lng > @ne.lng then @ne.lng = lng
    @counter.decr()
