###
# soql-completion.coffee
###
lexer  = require "./lexer"
parser = require "./parser"
Node   = require "./node"

tokenize = (soql) -> lexer.tokenize(soql)

parse = (tokens) -> parser.parse(tokens)

asyncMap = (arr, asyncFn, callback) ->
  cnt = arr.length
  rets = new Array(arr.length)
  return callback(rets) if cnt==0
  for a, i in arr
    asyncFn a, (ret) ->
      rets[i] = ret
      cnt--
      return callback(rets) if cnt==0

complete = (text, caret, callback) ->
  tokens = tokenize(text)
  { pos, inserting } = findCaretPosition(tokens, caret)
  tokens.splice(++pos, 0, [ "LITERAL" , "", 1, caret ]) if inserting
  debugTokens tokens
  target = tokens[pos]
  results = parseTokens(tokens, pos)
  asyncMap results, (r, cb) ->
    if typeof r == 'string'
      cb([ type: r, value: r ])
    else if r.type == 'ObjectType'
      getObjectTypes(r, cb)
    else if r.type == 'FieldName'
      getFieldNames(r, cb)
    else
      cb([])
  , (rets) ->
    candidates = []
    candidates.push.apply(candidates, ret) for ret in rets
    callback(candidates, target[3])


###
###
parseTokens = (tokens, pos) ->

  tryParse = (tokens, pos, depth=0) ->
    return [] if depth > 10
    debugTokens(tokens)
    try
      tree = parser.parse(tokens)
    catch e
      epos = e.pos - 1
      console.log e.message, "err pos=#{epos}, tgt pos=#{pos}"
      return [] unless e.expected?
      expected = (name.substring(1, name.length-1) for name in e.expected)
      console.log "expected", expected
      if epos == pos
        candidates = []
        for name in expected
          words = lexer.dictionary[name]
          candidates.push.apply(candidates, words) if words
        console.log candidates
      else
        etoken = getExpectedToken(expected, tokens[epos])
        tokens = Array.prototype.slice.call(tokens)
        tokens.splice(epos, 0, etoken)
        inc = if epos < pos then 1 else 0
        candidates = tryParse(tokens, pos+inc, depth+1)
      return candidates

    # tree.print()
    leafs = tree.flatten()
    return [ leafs[pos] ]

  tryParse(tokens, pos)

###
###
getExpectedToken = (names, actual) ->
  p = lexer.priority
  names = names.sort (n1, n2) ->
    p1 = p[n1] ? 100
    p2 = p[n2] ? 100
    if p1 > p2 then 1 else if p1 < p2 then -1 else 0
  for name in names
    words = lexer.dictionary[name] || lexer.examples[name]
    if words && words.length > 0
      return [ name, words[0], actual[2], actual[3] ]
  null

###
###
findCaretPosition = (tokens, caret) ->
  for i in [0...tokens.length - 1]
    tpos = tokens[i][3]
    tlen = tokens[i][1].length
    ntpos = tokens[i+1][3]
    if ntpos >= caret
      ret = { pos: i, inserting: caret > tpos + tlen }
      return ret
  { pos: tokens.length, inserting: true }

###
###
getObjectTypes = (node, callback) ->
  callback([
    { type: 'object', value: 'Account' }
    { type: 'object', value: 'Contact' }
    { type: 'object', value: 'Contract' }
  ])

###
###
getFieldNames = (node, callback) ->
  callback([
    { type: 'field', fieldType: 'id', value: 'Id' }
    { type: 'field', fieldType: 'text', value: 'Name' }
    { type: 'field', fieldType: 'id', value: 'AccountId' }
    { type: 'field', fieldType: 'reference', value: 'Account' }
  ])

###
###
debugTokens = (tokens) ->
  console.log (token[1]+"("+token[0]+":"+token[3]+")" for token in tokens).join(' ')


exports.tokenize = tokenize
exports.parse    = parse
exports.complete = complete

