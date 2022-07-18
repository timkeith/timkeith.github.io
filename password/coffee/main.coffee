#TODO: put and get options in url (see tracks)

React = require 'react'
ReactDOM = require 'react-dom'
{
  a,
  div,
  h2,
  p,
  span,
  table,
  tbody,
  td,
  tr,
} = require './lib/ReactDOM'
{classFactory,withKeys} = require './lib/ReactUtils'

main = () =>
  ReactDOM.render(
    Main decodeHash()
    document.getElementById('content')
  )

Main = classFactory
  displayName: 'Main'
  propTypes:
    numLetters: React.PropTypes.number.isRequired
  getInitialState: () ->
    numLetters:   @props.numLetters
  set: (key) ->
    (value) =>
      @state[key] = value
      @setState @state
      encodeHash(@state)
  refresh: (e) ->
    e.preventDefault()
    @forceUpdate()
  render: () ->
    div {},
      h2 'Password Generator'
      p class: 'desc',
        'Generate a password meant to be easy to type on a phone, of form:'
        span class: 'desc2', 'number $ upper-case lower-case...'
      table tbody {},
        tr {},
          td 'Number of letters: '
          td Selection selections: [6..12], selected: @state.numLetters, set: @set('numLetters')
        GenPassword { numLetters: @state.numLetters }

# selection: pass in choices and which one is selected and function to set
Selection = classFactory
  displayName: 'Selection'
  propTypes:
    selections: React.PropTypes.array.isRequired
    selected:   React.PropTypes.any.isRequired
    set:        React.PropTypes.func.isRequired
  render: () ->
    span withKeys(@renderSelection(selection) for selection in @props.selections)
  renderSelection: (selection) ->
    if selection == @props.selected
      span class: 'selection', selection
    else
      a class: 'selection', href: '#', onClick: @set(selection), selection
  set: (selection) ->
    (e) =>
      e.preventDefault()
      @props.set(selection)

GenPassword = classFactory
  displayName: 'GenPassword'
  propTypes:
    numLetters: React.PropTypes.number.isRequired
  randomInt: (limit) -> Math.floor(Math.random() * limit)
  randomLetter: () ->
    i = @randomInt(26)
    'abcdefghijklmnopqrstuvwxyz'.substring(i, i+1)
  genPassword: () ->
    letters = (@randomLetter() for i in [2 .. @props.numLetters])
    '' + @randomInt(10) + '$' + @randomLetter().toUpperCase() + letters.join('')
  render: () ->
    return tr {},
      td 'Password:'
      td class: 'password', span @genPassword()

encodeHash = (state) ->
  location.hash = "##{state.numLetters}"

decodeHash = () ->
  numLetters = 8
  if location.hash
    x = location.hash.replace(/^#/, '').split(',')
    if x.length > 0
      numLetters = parseInt(x[0], 10)
  return { numLetters: numLetters }

main()
