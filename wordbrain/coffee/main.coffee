{PropTypes} = require 'react'
PropTypes.stringOrNumber = PropTypes.oneOfType([PropTypes.string, PropTypes.number])
ReactDOM = require 'react-dom'
Lodash = require 'lodash'

Grid = require './Grid'

{tr,td,table,tbody,a,div,h1,h2,h3,input,span} = require './lib/ReactDOM'
{classFactory,withKeys} = require './lib/ReactUtils'
Selection = require './lib/Selection'

main = () =>
  ReactDOM.render(
    Main defaultSize: 4
    document.getElementById('content')
  )

Main = classFactory
  displayName: 'Main'
  propTypes:
    defaultSize: PropTypes.number.isRequired
  getInitialState: () ->
    gridSize: @props.defaultSize
  render: () ->
    div class: 'main',
      h2 'WordBrain Helper'
      div {},
        'Grid Size: '
        Selection
          selected:   @state.gridSize
          selections: [3 .. 6]
          set:        (size) => @setState gridSize: size
      WordBrain gridSize: @state.gridSize

WordBrain = classFactory
  displayName: 'WordBrain'
  propTypes:
    gridSize: PropTypes.number.isRequired
  getInitialState: () ->
    grid = new Grid(@props.gridSize)
    grid.onSet () => @forceUpdate()
    return gridSize: @props.gridSize, grid: grid
  componentWillReceiveProps: (nextProps) ->
    @setState gridSize: nextProps.gridSize
    @state.grid.resize(nextProps.gridSize)
  render: () ->
    div {},
      div class: 'buttons',
        a onClick: ((e) => @state.grid.clear()), 'Clear'
        a onClick: ((e) => @state.grid.random()), 'Random'
        a onClick: ((e) => @state.grid.transform()), 'Transform'
      GridTable gridSize: @state.gridSize, grid: @state.grid
      Answers   gridSize: @state.gridSize, grid: @state.grid

Answers = classFactory
  displayName: 'Answers'
  propTypes:
    gridSize: PropTypes.number.isRequired
    grid:     PropTypes.instanceOf(Grid).isRequired
  getInitialState: () ->
    # when grid changes, user must search again
    @props.grid.onSet () => @setState didSearch: false
    return {
      answerSize: 3
      didSearch: false
    }
  setAnswerSize: (answerSize) ->
    @setState answerSize: answerSize
    if @state.didSearch
      @_search(answerSize)
  search: (e) ->
    @_search(@state.answerSize)
    @setState didSearch: true
  _search: (answerSize) ->
    console.log 'answerSize:', answerSize
    @setState answers: @props.grid.search(answerSize)
  componentWillReceiveProps: (nextProps) ->
    @setState didSearch: false

  render: () ->
    div {},
      div class: 'answerSize',
        'Answer Size: '
        Selection selected: @state.answerSize, selections: [3 .. 8], set: @setAnswerSize
      if @state.didSearch
        ShowResults answerSize: @state.answerSize, answers: @state.answers
      else
        div class: 'buttons',
          a onClick: @search, 'Search'

ShowResults = classFactory
  displayName: 'ShowResults'
  propTypes:
    answerSize: PropTypes.number.isRequired
    answers:    PropTypes.arrayOf(PropTypes.string).isRequired
  getInitialState: () ->
    numShow: 0
  componentWillReceiveProps: (nextProps) ->
    if @props.answerSize != nextProps.answerSize
      @setState numShow: 0  # change answerSize -> switch back to showing 0
  render: () ->
    prefixes = Lodash.countBy(@props.answers, (answer) => answer.substr(0, @state.numShow))
    div class: 'result',
      h3 'Answers'
      if @props.answers.length == 0
        div 'None found'
      else
        div {},
          div class: 'numToShow',
            'Letters to show: '
            Selection
              selected:   @state.numShow
              selections: [0 .. @props.answerSize]
              set:        (n) => @setState numShow: n
          div class: 'letters',
            Lodash.map prefixes, (count, prefix) =>
              ShowResult key: prefix, prefix: prefix, count: count, answerSize: @props.answerSize

ShowResult = classFactory
  displayName: 'ShowResult'
  propTypes:
    prefix:     PropTypes.string.isRequired
    count:      PropTypes.number.isRequired
    answerSize: PropTypes.number.isRequired
  render: () ->
    result = Lodash.padEnd @props.prefix, @props.answerSize, '\u00a0' # NBSP
    div {},
      withKeys(span char for char in result)
      span class: 'count', if @props.count > 1 then " (#{@props.count})" else ''
      #if @props.count > 1
      #  span class: 'count', " (#{@props.count})"

GridTable = classFactory
  displayName: 'GridTable'
  propTypes:
    grid:      PropTypes.instanceOf(Grid).isRequired
  render: () ->
    size = @props.grid.size
    table class: 'grid', tbody {}, [0 ... size].map (row) =>
      GridRow
        key:       row
        grid:      @props.grid
        indexes:   [row*size ... (row+1)*size]

GridRow = classFactory
  displayName: 'GridRow'
  propTypes:
    grid:      PropTypes.instanceOf(Grid).isRequired
    indexes:   PropTypes.array.isRequired
  render: () ->
    tr {}, @props.indexes.map (index) =>
      GridCell key: index, grid: @props.grid, index: index

#TODO: pass grid all the way down to get letter for cell
GridCell = classFactory
  displayName: 'GridCell'
  propTypes:
    grid:      PropTypes.instanceOf(Grid).isRequired
    index:     PropTypes.number.isRequired
  onFocus: (e) ->
    @refs.input.select()
  onChange: (e) ->
    letter = @refs.input.value.toUpperCase()
    @refs.input.value = letter
    @props.grid.set(@props.index, letter)
  componentDidMount: () -> @doFocus()
  componentDidUpdate: () -> @doFocus()
  doFocus: () ->
    if @props.grid.isCurrIndex(@props.index)
      @refs.input.focus()
  render: () ->
    td input
      maxLength: 1
      ref:       'input'
      onChange:  @onChange
      onFocus:   @onFocus
      value:     @props.grid.get(@props.index)

#??? is this worth the trouble
Selection2 = classFactory
  displayName: 'Selection'
  propTypes:
    stateObject: PropTypes.object.isRequired
    selections:  PropTypes.arrayOf(PropTypes.stringOrNumber).isRequired
  set: (selection) ->
    (e) => e.preventDefault(); @props.stateObject.set(selection)
  renderSelection: (selection) ->
    selected = if selection == @props.stateObject.get() then 'selected' else ''
    a key: selection, class: selected, onClick: @set(selection), selection
  render: () ->
    span class: 'selections', @props.selections.map(@renderSelection)

# wrap fn in function that calls preventDefault on e first
preventDefault = (e, fn) ->
  e.preventDefault()
  return (args...) -> fn(args)

#TODO: class to encapsulate state object
# @get() gets the value, @set(value) sets it
class StateObject
  constructor: (@state, @setState, @name) ->
  get: () ->
    @state[@name]
  set: (value) ->
    obj = {}
    obj[@name] = value
    @setState obj

main()
