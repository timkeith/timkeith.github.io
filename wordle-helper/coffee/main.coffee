#TODO: put and get options in url (see tracks)
PropTypes = require 'prop-types'

React = require 'react'
ReactDOM = require 'react-dom'
{
  a
  button
  div
  form
  form
  h2
  input
  label
  p
  span
  table
  tbody
  td
  tr
} = require './lib/ReactDOM'
{classFactory, withKeys} = require './lib/ReactUtils'

NUM_GUESSES = 6
GUESS_NUMS = [0 .. NUM_GUESSES-1]
{NUM_LETTERS, log, assert} = require './Misc'
getMatchingAnswers = require './getMatchingAnswers'

LETTER_NUMS = [0 .. NUM_LETTERS-1]
COLORS = ['g', 'y', '-']

main = () =>
  ReactDOM.render(Main(), document.getElementById('content'))

Main = classFactory

  getInitialState: () ->
    answers:  undefined
    complete: (false) for ng in GUESS_NUMS
    letters:  ([]) for ng in GUESS_NUMS
    colors:   ([]) for ng in GUESS_NUMS

  setLetter: (ng, nl, letter) ->
    #console.log 'setLetter: ng:', ng, 'nl:', nl, 'letter:', letter
    @state.letters[ng][nl] = letter
    @setState letters: @state.letters
    @checkComplete(ng)

  hasLetter: (ng, nl) ->
    if !nl?
      return @hasLetter.bind(null, ng)
    !!@state.letters[ng][nl]

  setColor: (ng, nl, color) ->
    if !nl?
      return @setColor.bind(null, ng)
    if @state.colors[ng][nl]? and @state.colors[ng][nl] isnt color
      @state.complete[ng] = false  # to re-check for completeness
    @state.colors[ng][nl] = color
    @setState colors: @state.colors
    @checkComplete(ng)

  checkComplete: (ng) ->
    if !@state.complete[ng] && @isComplete(ng)
      @state.complete[ng] = true
      @setState complete: @state.complete
      @findWords()  # completeness state has changed

  isComplete: (ng) ->
    for nl in LETTER_NUMS
      if !@state.letters[ng][nl]
        return false
      if !@state.colors[ng][nl]
        return false
    return true

  firstIncomplete: () ->
    for ng in GUESS_NUMS
      if !@isComplete(ng)
        if ng > 0
          if @state.answers.length is 0
            return ng-1
          if @state.colors[ng-1].join('') is 'ggggg'
            return ng-1
        return ng
    return NUM_LETTERS

  findWords: () ->
    guesses = (
      @state.letters[ng].join('').toLowerCase() for ng in GUESS_NUMS when @state.complete[ng]
    )
    results = (@state.colors[ng].join('') for ng in GUESS_NUMS when @state.complete[ng])
    answers = getMatchingAnswers(guesses, results)
    @setState answers: answers

  render: () ->
    # only list guesses 1 past last complete
    div {},
      #ShowState state: @state
      h2 'Wordle Helper'
      table align: 'center',
        (
          tbody key: ng,
            GuessInput \
              ng: ng, letters: @state.letters[ng], colors: @state.colors[ng], setLetter: @setLetter
            RadioButtons hasLetter: @hasLetter(ng), setColor: @setColor(ng)
        ) for ng in [0 .. @firstIncomplete()]
      AnswersList answers: @state.answers

GuessInput = classFactory
  propTypes:
    ng:        PropTypes.number.isRequired
    letters:   PropTypes.array.isRequired
    colors:    PropTypes.array.isRequired
    setLetter: PropTypes.func.isRequired

  componentDidMount: () -> @focusInput(0, 0)

  focusInput: (ng, nl) -> document.querySelector("input[name=letter-#{ng}-#{nl}]")?.focus()

  letterChanged: (event) ->
    letter = event.target.value
    nl = getNumFromElem(event.target)
    @props.setLetter(@props.ng, nl, letter)
    nl = (nl + 1) % NUM_LETTERS
    @focusInput(@props.ng + (nl == 0 ? 1 : 0), nl)

  render: () ->
    tr class: 'guess',
      (
        td key: nl,
          input \
            name: "letter-#{@props.ng}-#{nl}", type: 'text', maxLength: 1,
            value: @props.letters[nl], class: "color-#{@props.colors[nl]}",
            onChange: @letterChanged
      ) for nl in LETTER_NUMS

AnswersList = classFactory
  propTypes:
    answers: PropTypes.array

  render: () ->
    if !@props.answers?
      div ''
    else if @props.answers.length == 0
      div 'No possible words'
    else
      div class: 'answers',
        div class: 'head', "#{@props.answers.length} possible words:"
        (
          div key: answer, class: 'answer', answer
        ) for answer in @props.answers

# Create set of checkboxes with given background color
RadioButtons = classFactory
  propTypes:
    hasLetter: PropTypes.func.isRequired
    setColor:  PropTypes.func.isRequired

  render: () -> tr {},
    (
      td key: nl, class: 'radio-buttons',
        div class: 'colored-radio', hidden: !@props.hasLetter(nl),
          (
            RadioButton key: color, nl: nl, color: color, setColor: @props.setColor
          ) for color in COLORS
    ) for nl in LETTER_NUMS

RadioButton = classFactory
  displayName: 'RadioButton'
  propTypes:
    nl:       PropTypes.number.isRequired
    color:    PropTypes.string.isRequired
    setColor: PropTypes.func.isRequired
  render: () ->
    input type: 'radio', name: "radio-#{@props.nl}", class: "color-#{@props.color}", \
      onChange: @props.setColor.bind(null, @props.nl, @props.color)

ShowState = classFactory
  propTypes:
    state: PropTypes.object.isRequired

  render: () ->
    {colors, letters, complete} = @props.state
    table {},
      tbody {},
        tr class: 'head',
          td 'State'
        tr class: 'head',
          td ''
          td ''
          (td key: num, style: {width: '3em'}, num) for num in LETTER_NUMS
        (
          [
            tr td "Guess ##{ng}"
            tr {},
              td ''
              td 'Letters:'
              (td key: num, letters[ng][num] ? '-') for num in LETTER_NUMS
            tr {},
              td ''
              td 'Colors:'
              (td key: num, colors[ng][num] ? '-') for num in LETTER_NUMS
            tr {},
              td ''
              td 'Complete:'
              td "#{complete}"
          ]
        ) for ng in GUESS_NUMS

getNumFromElem = (elem) ->
  parseInt(elem.name.replace(/^.*-/, ''), 10)

main()
