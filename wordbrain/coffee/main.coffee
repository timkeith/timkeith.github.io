{PropTypes} = require 'react'
PropTypes.stringOrNumber = PropTypes.oneOfType([PropTypes.string, PropTypes.number])
ReactDOM = require 'react-dom'
Lodash = require 'lodash'
Words = Lodash.countBy(require './words.js')

{tr,td,table,tbody,a,select,option,hr,section,button,div,form,h1,h2,h3,input,span} = require './lib/ReactDOM'
{classFactory,withKeys} = require './lib/ReactUtils'

main = () =>
  ReactDOM.render(
    Main {}
    document.getElementById('content')
  )

Main = classFactory
  displayName: 'Main'
  getInitialState: () ->
    grid:          new Grid(4)
    answerSize:    3
    answers:       []
    didSearch:     false
  setGridSize: (size) ->
    @setState grid: new Grid(+size)
    @setState didSearch: false
  clear: () ->
    @state.grid.clear()
    @setState didSearch: false
    @forceUpdate()
  setLetter: (index, letter) ->
    @state.grid.set(index, letter)
    @setState didSearch: false
  setAnswerSize: (answerSize) ->
    @setState answerSize: answerSize
    if @state.didSearch
      @_search(answerSize)
  search: (e) ->
    @_search(@state.answerSize)
    @setState didSearch: true
  _search: (answerSize) ->
    @setState answers: @state.grid.search(answerSize)

  render: () ->
    div class: 'main',
      h2 'WordBrain Cheater'
      div {},
        'Grid Size: '
        Selection selected: @state.grid.size, selections: [3 .. 6], set: @setGridSize
      div {},
        button onClick: @clear, 'Clear'
      GridTable size: @state.grid.size, setLetter: @setLetter
      div class: 'answerSize',
        'Answer Size: '
        Selection selected: @state.answerSize, selections: [3 .. 8], set: @setAnswerSize
      if @state.didSearch
        ShowResults answerSize: @state.answerSize, answers: @state.answers
      else
        div class: 'show',
          button onClick: @search, 'Search'

ShowResults = classFactory
  displayName: 'ShowResults'
  propTypes:
    answerSize: PropTypes.number.isRequired
    answers:    PropTypes.arrayOf(PropTypes.string).isRequired
  getInitialState: () ->
    numShow: 0
  componentWillReceiveProps: (nextProps) ->
    if @props.answerSize != nextProps.answerSize
      # change answerSize -> switch back to showing 0
      @setState numShow: 0
  setNumShow: (n) ->
    @setState numShow: n
  render: () ->
    prefixes = Lodash.countBy(@props.answers, (answer) => answer.substr(0, @state.numShow))
    div class: 'result',
      h3 'Results'
      if @props.answers.length == 0
        div 'None found'
      else
        div {},
          div class: 'numToShow',
            'Letters to show: '
            Selection selected: @state.numShow, selections: [0..@props.answerSize], set: @setNumShow
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
      withKeys(span char.toUpperCase() for char in result)
      if @props.count > 1
        span class: 'count', " (#{@props.count})"

GridTable = classFactory
  displayName: 'GridTable'
  propTypes:
    size:      PropTypes.number.isRequired
    setLetter: PropTypes.func.isRequired
  getInitialState: () ->
    currIndex: 0
  setLetter: (index, letter) ->
    if letter != ''
      @setState currIndex: index + 1
    @props.setLetter(index, letter)
  render: () ->
    size = @props.size
    table class: 'grid', tbody {}, [0 ... size].map (row) =>
      GridRow
        key:       row
        indexes:   [row*size ... (row+1)*size]
        currIndex: @state.currIndex
        setLetter: @setLetter

GridRow = classFactory
  displayName: 'GridRow'
  propTypes:
    indexes:   PropTypes.array.isRequired
    currIndex: PropTypes.number.isRequired
    setLetter: PropTypes.func.isRequired
  render: () ->
    tr {}, @props.indexes.map (index) =>
      isCurr = index == @props.currIndex
      GridCell key: index, index: index, isCurr: isCurr, setLetter: @props.setLetter

#TODO: pass grid all the way down to get letter for cell
GridCell = classFactory
  displayName: 'GridCell'
  propTypes:
    index:     PropTypes.number.isRequired
    isCurr:    PropTypes.bool.isRequired
    setLetter: PropTypes.func.isRequired
  onFocus: (e) ->
    @refs.input.select()
  onChange: (e) ->
    letter = @refs.input.value.toUpperCase()
    @refs.input.value = letter
    @props.setLetter(@props.index, letter)
  componentDidMount: () -> @doFocus()
  componentDidUpdate: () -> @doFocus()
  doFocus: () ->
    if @props.isCurr
      @refs.input.focus()
  render: () ->
    td {},
      input maxLength: 1, ref: 'input', onChange: @onChange, onFocus: @onFocus


class Grid
  constructor: (@size) ->
    @grid = [0 ... @size**2].map (index) =>
      index: index, letter: '?', adjacent: @_adjacent(index)

  show: () ->
    console.log @grid.map((cell) => cell.letter).join(' ')

  clear: () ->
    [0 ... @size**2].map (index) => @set(index, '?')

  set: (index, letter) ->
    @grid[index].letter = letter

  search: (answerSize) ->
    gs = new GridSearch(@grid, answerSize)
    return gs.search()

  _adjacent: (index) ->
    i = index // @size
    j = index %% @size
    result = []
    for i2 in [i-1 .. i+1]
      if i2 >= 0 && i2 < @size
        for j2 in [j-1 .. j+1]
          if j2 >= 0 && j2 < @size
            index2 = @toIndex(i2, j2)
            if index2 != index
              result.push(index2)
    return result

  toIndex: (i, j) -> i * @size + j


class GridSearch
  constructor: (@grid, @answerSize) ->

  search: () ->
    @found = {}
    @used = {}
    [0 ... @grid.length].map((index) => @_search('', index))
    return Object.keys(@found).sort()

  # Add letters to curr starting from this index, adding words found to @found
  _search: (curr, index) ->
    curr += @grid[index].letter.toLowerCase()
    if curr.length < @answerSize
      @used[index] = 1
      @grid[index].adjacent.map((adj) => @used[adj] || @_search(curr, adj))
      @used[index] = 0
    else if Words[curr]
      @found[curr] = 1
    # else at the end but not a word

#NOTE: copied from password tool
# Pass in choices and which one is selected; `set` when one of `selections` when selected.
# Styling: all is wrapped in span.selection; selected choice is a.selected
Selection = classFactory
  displayName: 'Selection'
  propTypes:
    selections: PropTypes.arrayOf(PropTypes.stringOrNumber).isRequired
    selected:   PropTypes.stringOrNumber.isRequired
    set:        PropTypes.func.isRequired
  set: (selection) ->
    (e) => e.preventDefault(); @props.set(selection)
  renderSelection: (selection) ->
    selected = if selection == @props.selected then 'selected' else ''
    a key: selection, class: selected, href: '#', onClick: @set(selection), selection
  render: () ->
    span class: 'selections', @props.selections.map(@renderSelection)

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
    a key: selection, class: selected, href: '#', onClick: @set(selection), selection
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
