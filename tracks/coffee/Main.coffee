_ = require 'underscore'
$ = require 'jquery'
React = require 'react'
PropTypes = React.PropTypes
ReactDOM = require 'react-dom'
#update = require 'react-addons-update'
http = require 'http'
expect = require('chai').expect
util = require './util'
{a,table,tbody,tr,th,td,section,button,div,form,h1,h2,input,span,hr} = require './lib/ReactDOM'
{classFactory,withKeys,group} = require './lib/ReactUtils'


extend = (obj, key, value) ->
  kv = {}
  kv[key] = value
  return _.extend(obj, kv)


main = () ->
  ReactDOM.render(
    Main selectedDir: location.hash.replace(/^#/, '')
    document.getElementById('main-content')
  )

Main = classFactory
  displayName: 'Main'
  propTypes:
    selectedDir: PropTypes.string
  getInitialState: () ->
    dirInfos:    []
    selectedDir: @props.selectedDir
  componentDidMount: () ->
    $.ajax
      url:     util.getUrl('main.json')
      type:    'GET'
      success: (data) =>
        console.log 'data:', data
        @setState dirInfos: data
      error:   (error) ->
        console.log 'ERROR: get request failed:', error

  selectDir: (dir) ->
    if dir == @state.selectedDir
      @setState selectedDir: ''
      location.hash = ''
    else
      @setState selectedDir: dir
      location.hash = "##{dir}"

  render: () ->
    div {}, (
      ShowDir(
        key:        info.dir
        dir:        info.dir
        name:       info.name
        tracks:     info.data
        selectDir:  @selectDir
        isSelected: @state.selectedDir == info.dir
      ) for info in @state.dirInfos
    )

ShowDir = classFactory
  displayName: 'ShowDir'
  propTypes:
    dir:        PropTypes.string.isRequired
    name:       PropTypes.string.isRequired
    tracks:     PropTypes.arrayOf(PropTypes.object).isRequired
    selectDir:  PropTypes.func.isRequired    # call when this is selected, pass in dir name
    isSelected: PropTypes.bool.isRequired    # is this dir selected?
  getInitialState: () ->
    return selectedTracks: {}  # dir -> true for those that are selected
  selectTrack: (path, track) ->
    @setState selectedTracks: extend(@state.selectedTracks, path, track)
  selectDir: (e) ->
    e.preventDefault()
    @props.selectDir(@props.dir)
  getSelectedTracksRow: () ->
    selected = @state.selectedTracks
    tracks = _.sortBy(key for key, value of selected when value?, (x) -> selected[x].date)
    tracks.reverse()
    num = tracks.length
    return tr class: 'map',
      td colspan: '3',
        a
          disabled: num == 0
          target: '_blank'
          href: util.getUrl("map.html?#{tracks.join('&')}")
          'Map'
        " - #{num} selected track#{if num != 1 then 's' else ''}"
  showTrack: (track) ->
    ShowTrack dir: @props.dir, track: track, selectTrack: @selectTrack
  render: () ->
    rows = [
      tr class: 'head',
        td colspan: 3,
          a href: "##{@props.dir}", onClick: @selectDir, @props.name
    ]
    if @props.isSelected
      rows.push(
        ShowTrack dir: @props.dir, track: track, selectTrack: @selectTrack \
          for track in @props.tracks)
      rows.push(@getSelectedTracksRow())
    table {}, tbody {}, withKeys(rows)

ShowTrack = classFactory
  displayName: 'ShowTrack'
  propTypes:
    dir:         PropTypes.string.isRequired
    track:       PropTypes.object.isRequired
    selectTrack: PropTypes.func.isRequired
  getInitialState: () ->
    info: {}
    path: @props.track.path.replace(/(.*)\.json$/, '/$1')
  checkEvent: (e) ->
    #@props.selectTrack(@state.path, e.target.checked)
    @props.selectTrack(@state.path, if e.target.checked then @props.track else undefined)

  getDateString: () ->
    new Date(@props.track.date).toDateString().replace(
      /^\w\w\w (\w\w\w) 0?(\d+) (\d\d\d\d)$/, '$1 $2, $3')

  render: () ->
    url = util.getUrl("map.html?#{@state.path}")
    tr {},
      td class: 'indent',
        input type: 'checkbox', onChange: @checkEvent
      td @getDateString()
      td {},
        a href: url, target: '_blank', @props.track.name


if not window.tsk? then window.tsk = {}
window.tsk.Maps = main: main
