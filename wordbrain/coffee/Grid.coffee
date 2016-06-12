Lodash = require 'lodash'
{words,frequencies} = require './Words.js'
#Words = Lodash.countBy(require './Words.js')
Words = Lodash.countBy words

class Grid
  constructor: (size) ->
    @_init(size)
    @onSetFns = []

  resize: (size) -> @_init(size)

  # Register fn(index, letter) to be called when a cell is set
  onSet: (fn) -> @onSetFns.push(fn)
  _onSet: (index, letter) -> @onSetFns.map (fn) -> fn(index, letter)

  isCurrIndex: (index) -> index == @currIndex
  toString:    ()      -> @grid.map((cell) => cell.letter).join(' ')
  show:        ()      -> console.log @toString()
  clear:       ()      -> [0 ... @size**2].map (index) => @set(index, '')
  random:      ()      ->
    r = new RandomLetter(frequencies)
    [0 ... @size**2].map (index) => @set(index, r.gen())
  get:         (index) -> @grid[index].letter
  search:      (size)  -> return new GridSearch(@grid, size).search()

  set: (index, letter) ->
    @grid[index].letter = letter
    @currIndex = index + 1
    @_onSet index, letter

  # perform the next transformation on the grid
  transform: () ->
    @_transform (i, j) => [j, @size-i-1]  # rotate clockwise
    @_nTransform += 1
    if @_nTransform %% @size == 0
      @_transform (i, j) => [@size-j-1, @size-i-1]  # reflect in line i==j

  # Transform letters based in this mapping of i,j: fn: (i, j) -> [i2, j2]
  _transform: (fn) ->
    letters = []
    for i in [0 ... @size]
      for j in [0 ... @size]
        [i2, j2] = fn(i, j)
        letters[@_index(i2, j2)] = @grid[@_index(i, j)].letter
    letters.map (letter, index) => @grid[index].letter = letter
    @currIndex = 16
    @_onSet 0, letters[0]

  _letters: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split ''

  _randomLetter: () -> @_letters[Math.floor(Math.random() * @_letters.length)]

  _adjacent: (index) ->
    i = index // @size
    j = index %% @size
    result = []
    for i2 in [i-1 .. i+1]
      if i2 >= 0 && i2 < @size
        for j2 in [j-1 .. j+1]
          if j2 >= 0 && j2 < @size
            index2 = @_index(i2, j2)
            if index2 != index
              result.push(index2)
    return result

  _index: (i, j) -> i * @size + j

  # initialize the grid, either from constructor or resize()
  _init: (size) ->
    @size = size
    @grid = [0 ... size**2].map (index) =>
      index: index, letter: '', adjacent: @_adjacent(index)
    @currIndex = 0
    @_nTransform = 0


class GridSearch
  constructor: (@grid, @answerSize) ->

  search: () ->
    # Mark empty cells as already used
    @used = Lodash.countBy(@grid.filter((elem) -> elem.letter == ''), 'index')
    @found = {}
    [0 ... @grid.length].map (index) => @_search('', index)
    return Object.keys(@found).sort()

  # Add letters to curr starting from this index, adding words found to @found
  _search: (curr, index) ->
    if @used[index]
      return
    curr += @grid[index].letter
    if curr.length < @answerSize
      @used[index] = 1
      @grid[index].adjacent.map (adj) => @_search(curr, adj)
      @used[index] = 0
    else if Words[curr]
      @found[curr] = 1
    # else at the end but not a word

class RandomLetter
  constructor: (@frequencies) ->
    @total = Lodash.sum(Lodash.map @frequencies, (value) -> value)

  gen: () ->
    r = Math.floor(Math.random() * @total)
    for letter, count of @frequencies
      r -= count
      if r < 0
        return letter
    return '?'  # should not happen?


module.exports = Grid
