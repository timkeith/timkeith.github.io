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
      years: [now.year()..now.year()+4]
    }
  componentDidMount: () ->
  setMonth: (e) -> @setState month: e.target.value
  setYear: (e) -> @setState year: e.target.value
  next: (e) -> @incrMonth(e, +1)
  prev: (e) -> @incrMonth(e, -1)
  curr: () -> Moment("#{@state.month} #{@state.year}", 'MMM YYYY')
  incrMonth: (e, incr) ->
    e.preventDefault()
    curr = @curr()
    curr.add(incr, 'months')
    @setState month: curr.format('MMM'), year: curr.year()
  getFullMonth: () ->
    next = @curr()
    next.add(1, 'months')
    return { curr: @curr().format('MMMM'), next: next.format('MMMM') }
  getMonths: () ->
    ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']

  render: () ->
    div {},
      div class: 'nav',
        a href: '#', onClick: @prev, '<<'
        ' '
        select value: @state.month, onChange: @setMonth,
          (option key: month, value: month, month for month in @getMonths())
        ' '
        select value: @state.year, onChange: @setYear,
          (option key: year, value: year, year for year in @state.years)
        ' '
        a href: '#', onClick: @next, '>>'
      table {}, tbody {}, @_rows()

  _head1: () ->
    tr class: 'head1', key: '99',
      td colSpan: '4', @state.year
      td class: 'months',
        @getFullMonth().curr
        ' to '
        @getFullMonth().next
  _rows: () ->
    rows = []
    rows.push(
      @_head1()
      #tr class: 'head1', key: '99',
      #  td colSpan: '4', @state.year
      #  td class: 'months',
      #    @getFullMonth().curr
      #    ' to '
      #    @getFullMonth().next
    )
    rows.push(
      tr class: 'head2', key: '98',
        td {}
        td {}
        td 'AM'
        td 'PM'
        td 'NOTES'
    )
    m = @curr()
    m.date(16)
    while true
      rows.push(
        tr key: m.date(),
          td style: border: '1px solid black', m.format('dd')
          td m.date()
          td {}
          td {}
          td style: width: '80%'
      )
      m.add(1, 'days')
      break if m.date() == 16
    rows.push(tr key: 200, class: 'divider', td {})
    for i in [1 .. 8]
      rows.push(
        tr key: i+100, class: 'notes',
          td colSpan: 2, if i == 1 then 'Notes:' else ''
          td colSpan: 3, class: 'underline', ' '
      )
    return rows

main()
