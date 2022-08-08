React = require 'react'
_ = require 'underscore'

module.exports =
  # helper to create a class factory from a class spec
  #classFactory: (spec) ->
  #  React.createFactory(React.createClass(spec))

  classFactory: (spec) ->
    c = React.createClass(spec)
    return (attrs, children...) -> React.createElement(c, attrs, children)

  # Add keys to elements in arr
  withKeys: (arr) ->
    _.map arr, (elem, index) ->
      if elem.key == null
        React.cloneElement(elem, key: index)
      else
        elem

  # group elems under span, flatten arrays
  group: (args) ->
    React.DOM.span {}, (
      for index, elem of _.flatten(args)
        if elem.key == null
          React.cloneElement(elem, key: index)
        else
          elem
    )
