{PropTypes} = require 'react'
PropTypes.stringOrNumber = PropTypes.oneOfType([PropTypes.string, PropTypes.number])
{a,div,span} = require './ReactDOM'
{classFactory} = require './ReactUtils'

#NOTE: copied from password tool
# Pass in choices and which one is selected; `set` when one of `selections` when selected.
# Styling: all is wrapped in span.selections; selected choice is a.selected
Selection = classFactory
  displayName: 'Selection'
  propTypes:
    selections: PropTypes.arrayOf(PropTypes.stringOrNumber).isRequired
    selected:   PropTypes.stringOrNumber.isRequired
    set:        PropTypes.func.isRequired
  set: (selection) ->
    (e) => e.preventDefault(); @props.set(selection)
  render: () ->
    span class: 'selections',
      @props.selections.map (selection) =>
        a
          key:     selection
          class:   if selection == @props.selected then 'selected' else ''
          onClick: () => @props.set(selection)
          selection

module.exports = Selection
