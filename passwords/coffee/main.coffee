#TODO: put and get options in url (see tracks)

_ = require 'underscore'
Moment = require 'moment'
React = require 'react'
ReactDOM = require 'react-dom'
Words = require './words.js'

{tr,td,table,tbody,a,select,option,hr,section,button,div,form,h1,h2,input,span} = require './lib/ReactDOM'
{classFactory,withKeys} = require './lib/ReactUtils'

YES = 'Yes'
NO = 'No'
YES_NO = [YES, NO]
SPECIAL = '! @ # $ % ^ & * ( ) _ + - = { } | [ ] : " ; < > ? , . /'.split /\s/

main = () =>
  ReactDOM.render(
    Main decodeHash()
    document.getElementById('content')
  )

Main = classFactory
  displayName: 'Main'
  propTypes:
    numPasswords: React.PropTypes.number.isRequired
    numWords:     React.PropTypes.number.isRequired
    numDigits:    React.PropTypes.number.isRequired
    upperCase:    React.PropTypes.string.isRequired
    special:      React.PropTypes.string.isRequired
  getInitialState: () ->
    numPasswords: @props.numPasswords
    numWords:     @props.numWords
    numDigits:    @props.numDigits
    upperCase:    @props.upperCase
    special:      @props.special
  set: (key) ->
    (value) =>
      @state[key] = value
      @setState @state
      encodeHash(@state)
  refresh: (e) ->
    e.preventDefault()
    @forceUpdate()
  render: () ->
    console.log 'Main.render'
    div {},
      h2 'Password Generator'
      table tbody {},
        tr {},
          td 'Number of words: '
          td Selection selections: [2..5], selected: @state.numWords, set: @set('numWords')
        tr {},
          td 'Number of digits: '
          td Selection selections: [0 .. 5], selected: @state.numDigits, set: @set('numDigits')
        tr {},
          td 'Include uppercase: '
          td Selection selections: YES_NO, selected: @state.upperCase, set: @set('upperCase')
        tr {},
          td 'Include special: '
          td Selection selections: YES_NO, selected: @state.special, set: @set('special')
      table class: 'passwords', tbody {},
        tr class: 'head',
          td "#{@state.numPasswords} random passwords: "
          td a href: '#', onClick: @refresh, 'refresh'
        (
          GenPassword {
            key: i
            numWords:  @state.numWords
            numDigits: @state.numDigits
            upperCase: @state.upperCase == YES
            special:   @state.special == YES
          } for i in [1 .. @state.numPasswords]
        )

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
    numWords:  React.PropTypes.number.isRequired
    numDigits: React.PropTypes.number.isRequired
    upperCase: React.PropTypes.bool.isRequired
    special:   React.PropTypes.bool.isRequired
  randWords: () ->
    (Words[Math.floor(Math.random() * Words.length)] for num in [1..@props.numWords])
  randDigits: () ->
    (Math.floor(Math.random() * 10) for num in [1 .. @props.numDigits])
  randSpecial: () ->
    if @props.special
      SPECIAL[Math.floor(Math.random() * SPECIAL.length)]
    else
      ''
  upperCase: (word) ->
    if @props.upperCase
      #word.replace(/[aeiou]/, (c) -> c.toUpperCase())
      word.replace(/(.)([aeiou])/, (match, p1, p2) -> p1 + p2.toUpperCase())
    else
      word
  render: () ->
    words = @randWords()
    digits = @randDigits().join('')
    special = @randSpecial()
    password = digits + special + (@upperCase(word) for word in words).join('')
    return tr {},
      td class: 'password', span password
        #input type: 'text', readOnly: true, value: password
      td {},
        span class: 'part', digits
        if special then span class: 'part', special else ''
        withKeys(span class: 'part', word for word in words)

encodeHash = (state) ->
  console.log 'encodeHash:', state
  location.hash = "#!#{state.numWords},#{state.numDigits},#{state.upperCase},#{state.special}"

decodeHash = () ->
  result =
    numPasswords: 4
    numWords:     2
    numDigits:    2
    upperCase:    'Yes'
    special:      'No'
  hash = location.hash
  if hash
    x = hash.replace(/^#!/, '').split(',')
    if x.length > 0
      result.numWords = parseInt(x[0], 10)
    if x.length > 1
      result.numDigits = parseInt(x[1], 10)
    if x.length > 2
      result.upperCase = x[2]
    if x.length > 3
      result.special = x[3]
  return result

main()
