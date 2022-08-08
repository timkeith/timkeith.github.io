{NUM_LETTERS, log, assert} = require './Misc'
Words = require './Words'

# guesses is an array of words that were guessed
# results is a same-length array of results like 'gy-g-'
getMatchingAnswers = (guesses, results) ->
  assert guesses.length == results.length, 'length mismatch in getMatchingAnswers'
  result = []
  for word in Words
    if allGuessesMatch(word, guesses, results)
      result.push(word)
  return result

allGuessesMatch = (word, guesses, results) ->
  for i in [0 .. guesses.length-1]
    check = checkGuess(guesses[i], word)
    if checkGuess(guesses[i], word) != results[i]
      return false
  return true

# Return combination of g/y/- for a guess relative to an answer
checkGuess = (guess, answer) ->
  num = guess.length - 1
  g = guess.split ''
  a = answer.split ''
  result = ('-' for i in [0 .. num])
  for i in [0 .. num]
    if g[i] == a[i]
      result[i] = 'g'
      a[i] = ''
      g[i] = undefined
  for i in [0 .. num]
    if g[i]
      for j in [0 .. num]
        if a[j] == g[i]
          result[i] = 'y'
          break
  return result.join('')

#matches = getMatchingAnswers(['soare'], ['g-y-y'])

#module.exports.getMatchingAnswers = getMatchingAnswers
module.exports = getMatchingAnswers
