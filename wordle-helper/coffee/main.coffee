#TODO: put and get options in url (see tracks)
PropTypes = require 'prop-types'

React = require 'react'
ReactDOM = require 'react-dom'
{
  div
  h2
  input
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
    lastGuess: 0
    complete: (false) for ng in GUESS_NUMS
    letters:  ([]) for ng in GUESS_NUMS
    colors:   ([]) for ng in GUESS_NUMS

  setLetter: (ng, nl, letter) ->
    @state.letters[ng][nl] = letter
    @setState letters: @state.letters
    #@checkComplete(ng)

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
    if @isComplete(ng) and ng == @state.lastGuess
      #TODO: combine complete,letters,colors into one map
      #TODO: use length of array in place of lastGuess?
      @setState lastGuess: @state.lastGuess + 1
      @setState complete: @state.complete.concat(false)
      @setState letters: @state.letters.concat([[]])
      @setState colors: @state.colors.concat([[]])

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

  findWords: () ->
    guesses = (@state.letters[ng].join('').toLowerCase() \
      for ng in [0..@state.lastGuess] when @state.complete[ng])
    results = (@state.colors[ng].join('') \
      for ng in [0..@state.lastGuess] when @state.complete[ng])
    @setState answers: getMatchingAnswers(guesses, results)

  render: () ->
    lastGuess = @state.lastGuess
    if @state.answers? && @state.answers.length <= 1
      lastGuess -= 1  # don't need another guess: have the answer (or there is no answer)
    div {},
      #ShowState state: @state
      h2 'Wordle Helper'
      table align: 'center',
        (
          tbody key: ng,
            GuessInput {
              ng: ng, letters: @state.letters[ng], colors: @state.colors[ng],
              setLetter: @setLetter
            }
            RadioButtons hasLetter: @hasLetter(ng), setColor: @setColor(ng)
        ) for ng in [0 .. lastGuess]
      AnswersList answers: @state.answers

GuessInput = classFactory
  propTypes:
    ng:        PropTypes.number.isRequired
    letters:   PropTypes.array.isRequired
    colors:    PropTypes.array.isRequired
    setLetter: PropTypes.func.isRequired

  componentDidMount: () ->
    if not @props.letters[0]?
      @focusInput(@props.ng, 0)

  focusInput: (ng, nl) -> document.querySelector("input[name=letter-#{ng}-#{nl}]")?.focus()

  letterChanged: (event) ->
    letter = event.target.value
    nl = getNumFromElem(event.target)
    @props.setLetter(@props.ng, nl, letter)
    @focusInput(@props.ng, nl + 1)
    #nl = (nl + 1) % NUM_LETTERS
    #@focusInput(@props.ng + (nl == 0 ? 1 : 0), nl)

  render: () ->
    tr class: 'guess',
      (
        td key: nl,
          input {
            name: "letter-#{@props.ng}-#{nl}", type: 'text', maxLength: 1,
            value: @props.letters[nl], class: "color-#{@props.colors[nl]}",
            onChange: @letterChanged
          }
      ) for nl in LETTER_NUMS

AnswersList = classFactory
  propTypes:
    answers: PropTypes.array

  render: () ->
    answers = @props.answers
    if !answers?
      div 'Enter guess and result'
    else if answers.length == 0
      div class: 'head', 'No possible answers'
    else if answers.length == 1
      div class: 'head',
        "Answer: "
        span class: 'answer', answers[0]
    else
      div class: 'answers',
        div class: 'head', "#{answers.length} possible answers:"
        (
          div key: answer, class: 'answer', answer
        ) for answer in answers

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
        ) for ng in [0..@state.lastGuess]

getNumFromElem = (elem) ->
  parseInt(elem.name.replace(/^.*-/, ''), 10)

main()
