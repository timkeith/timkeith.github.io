React = require 'react'
_ = require 'underscore'

# These versions of DOM element factories allow for 'class:' instead of 'className:'
# and the attrs are optional.

ReactDOM = {}
for name, value of React.DOM
  do(name) ->
    ReactDOM[name] = (attrs, children...) ->
      #console.log 'name', name
      #console.log 'attrs', attrs
      #console.log 'children', children
      args = [attrs].concat(children)
      #if attrs?.__proto__._isReactElement || _.isArray(attrs) || !_.isObject(attrs)
      if isReactElement(attrs) || _.isArray(attrs) || !_.isObject(attrs)
        #console.log 'NO ATTRS'
        args = [null].concat(args)
      else
        #console.log 'YES ATTRS'
        if attrs.class?
          attrs.className = attrs.class
          delete attrs.class
        if attrs.for?
          attrs.htmlFor = attrs.for
          delete attrs.for
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
