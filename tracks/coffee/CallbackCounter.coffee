class CallbackCounter
  constructor: (@count, @done) ->
    if typeof count == 'function'
      @done = count
      @count = 0
    @results = []

  incr: (n) ->
    @count += n || 1

  decr: () ->
    if @count <= 0
      throw new Error 'count is negative'
    @count -= 1
    if @count == 0
      @done()

module.exports = CallbackCounter
