React = require 'react'
_ = require 'underscore'

# These versions of DOM element factories allow for 'class:' instead of 'className:'
# and the attrs are optional.
# Mappings of attrs:
#   className -> class
#   htmlFor -> for
#   colSpan -> colspan

ReactDOM = {}
for name, value of React.DOM
  do(name) ->
    ReactDOM[name] = (attrs, children...) ->
      args = [attrs].concat(children)
      if isReactElement(attrs) || _.isArray(attrs) || !_.isObject(attrs)
        args = [null].concat(args)
      else
        if attrs.class?
          attrs.className = attrs.class
          delete attrs.class
        if attrs.for?
          attrs.htmlFor = attrs.for
          delete attrs.for
        if attrs.colspan?
          attrs.colSpan = attrs.colspan
          delete attrs.colspan
      #if attrs.key?
      #  console.log 'have key', attrs
      #  console.log 'elem', React.createElement.apply(null, [name].concat(args))
      return React.createElement.apply(null, [name].concat(args))

isReactElement = (obj) ->
  if typeof obj != 'object' || obj == null
    return false
  return obj.$$typeof != undefined && obj._store? && obj.key != undefined &&
    obj.props != undefined && obj.type?

# button class: 'btn', ...
btn = (attrs, child) ->
  if attrs?.__proto__._isReactElement || _.isArray(attrs) || !_.isObject(attrs)
    child = attrs
    attrs = {}
  if attrs.class?
    attrs.class += ' btn'
  else
    attrs.class = 'btn'
  return ReactDOM.button(attrs, child)
  #return React.createElement('button', attrs, child)
  #args = ['button', attrs].concat(children)
  #console.log 'args', args
  #return React.createElement.apply(null, args)

module.exports = ReactDOM
