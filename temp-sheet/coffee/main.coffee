# Different version of google maps api
# https://github.com/istarkov/google-map-react

_ = require 'underscore'
Moment = require 'moment'

React = require 'react'
ReactDOM = require 'react-dom'

{tr,td,table,tbody,a,select,option,hr,section,button,div,form,h1,h2,input,span} = require './lib/ReactDOM'

{classFactory,withKeys} = require './lib/ReactUtils'

main = () ->
  ReactDOM.render(
    Main {}
    document.getElementById('content')
  )

Main = classFactory
  displayName: 'Main'
  getInitialState: () ->
    now = Moment()
    return {
      month: now.format('MMM')
      year:  now.year()
    }
  componentDidMount: () ->
  setMonth: (e) -> @setState month: e.target.value
  setYear: (e) -> @setState year: e.target.value
  nextMonth: (e) -> @incrMonth(e, +1)
  prevMonth: (e) -> @incrMonth(e, -1)
  curr: () -> Moment("#{@state.month} #{@state.year}", 'MMM YYYY')
  # add incr months to curr and return as {month:,year:}
  addToCurr: (incr) ->
    curr = @curr()
    curr.add(incr, 'months')
    return moment: curr, month: curr.format('MMM'), year: curr.year()
  incrMonth: (e, incr) ->
    e.preventDefault()
    @setState @addToCurr(incr)

  getRows: (incr) ->
    {moment,month,year} = @addToCurr(incr)
    rows = []
    rows.push(
      tr class: 'head', key: '98',
        td {}
        td {}
        td 'Lo'
        td 'Hi'
        td class: 'notes',
          a class: 'nav', href: '#', onClick: @prevMonth, '<<'
          ' '
          month
          ' '
          year
          ' '
          a class: 'nav', href: '#', onClick: @nextMonth, '>>'
        td {}
    )
    m = moment
    m.date(1)
    while true
      rows.push(
        tr key: m.date(),
          td m.date()
          td m.format('dd')
          td {}
          td {}
          td class: 'notes'
          td {}
      )
      m.add(1, 'days')
      break if m.date() == 1
    return rows

  getTable: (incr) -> table class: 'month', tbody {}, @getRows(incr)

  render: () ->
    table class: 'main',
      tbody {},
        tr class: 'row1',
          td class: 'col1', @getTable(0)
          td class: 'col2', @getTable(1)
        tr class: 'row2',
          td class: 'col1', @getTable(2)
          td class: 'col2', @getTable(3)

      #div class: 'head',
      #  a class: 'nav', href: '#', onClick: @prevMonth, '<<'
      #  ' '
      #  @state.month
      #  ' '
      #  @state.year
      #  ' '
      #  a class: 'nav', href: '#', onClick: @nextMonth, '>>'

main()
