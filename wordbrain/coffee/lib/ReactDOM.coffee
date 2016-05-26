React = require 'react'
_ = require 'underscore'

# These versions of DOM element factories allow for 'class:' instead of 'className:'
# and the attrs are optional.

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
        if name == 'a' and not attrs.href?
          attrs.href = '#'
          onClick = attrs.onClick
          if onClick?
            attrs.onClick = (e) -> e? and e.preventDefault(); onClick()
          else
            attrs.onClick = (e) -> e.preventDefault();
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

module.exports = ReactDOM
