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
  # debugTokens tokens
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
  ,
  (rets) ->
    candidates = []
    candidates.push.apply(candidates, ret) for ret in rets
    callback(candidates, target[3])


###
###
parseTokens = (tokens, pos) ->

  tryParse = (tokens, pos, depth=0) ->
    return [] if depth > 10
    # debugTokens(tokens)
    try
      tree = parser.parse(tokens)
    catch e
      epos = e.pos - 1
      return [] unless e.expected?
      expected = (name.substring(1, name.length-1) for name in e.expected)
      if epos == pos
        candidates = []
        for name in expected
          words = lexer.dictionary[name]
          candidates.push.apply(candidates, words) if words
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
    ttag = tokens[i][0]
    tpos = tokens[i][3]
    tlen = tokens[i][1].length
    ntpos = tokens[i+1][3]
    if ntpos >= caret
      inserting =
        caret > tpos + tlen ||
        (caret == tpos + tlen && /^(DOT|SEPARATOR)$/.test(ttag))
      return { pos: i, inserting: inserting }
  { pos: tokens.length, inserting: true }

###
###
getObjectTypes = (node, callback) ->
  handleError = (err) ->
    console.error(err)
    callback(null)

  selectTypeRegexp = /^(SelectQuery|InnerSelect)$/
  selectNode = node.findParent(selectTypeRegexp)
  return handleError(message: "Not inside of select node.") unless selectNode
  outerSelectNode = selectNode.findParent(selectTypeRegexp)
  # cannot be nested over 2 level
  if outerSelectNode?.findParent(selectTypeRegexp)
    return handleError(message: "Nested more than 2 levels")

  if outerSelectNode # inner select query
    objectType = outerSelectNode.find('ObjectType')?.value
    getConnection().describeSObject objectType, (err, res) ->
      return handleError(err) if err
      candidates =
        for r in res.childRelationships ? [] when r.relationshipName?
            type: 'childRelationship', value: r.relationshipName
      callback(candidates)
  else # root query
    getConnection().describeGlobal (err, res) ->
      return handleError(err) if err
      candidates =
        for s in res.sobjects when String(s.queryable) == "true"
          type: 'object', value: s.name
      callback(candidates)


###
###
getFieldNames = (node, callback) ->

  handleError = (err) ->
    console.error(err)
    callback([])

  handleFields = (fields) ->
    candidates = []
    for field in fields
      if !(inWhereClause && String(field.filterable) == "false") &&
         !(inOrderClause && String(field.sortable) == "false") &&
         !(inGroupClause && String(field.groupable) == "false")

        if field.type == 'reference'
          candidates.push
            type: 'field'
            fieldType: 'id'
            label: field.label
            value: field.name
          candidates.push
            type: 'field'
            fieldType: 'reference'
            label: field.label.replace(/\s+id$/ig, '')
            value: field.relationshipName
        else
          candidates.push
            type: 'field'
            fieldType: field.type
            label: field.label
            value: field.name
    callback(candidates)

  parentFields = []
  n = node
  parentFields.unshift(n.value) while n = n.findPrevious('FieldName', 'SelectField')

  selectTypeRegexp = /^(SelectQuery|InnerSelect)$/
  selectNode = node.findParent(selectTypeRegexp)
  return handleError( message: "Not inside of select node." ) unless selectNode
  outerSelectNode = selectNode.findParent(selectTypeRegexp)
  # cannot be nested over 2 level
  if outerSelectNode?.findParent(selectTypeRegexp)
    return handleError( message: "Nested more than 2 levels" )

  inWhereClause = node.findParent("WhereClause", selectTypeRegexp)?
  inOrderClause = node.findParent("OrderClause", selectTypeRegexp)?
  inGroupClause = node.findParent("GroupClause", selectTypeRegexp)?

  if outerSelectNode # inner select query
    objectType = outerSelectNode.find('ObjectType')?.value
    relationshipName = selectNode.find('ObjectType')?.value

    console.log "objectType=#{objectType}, relationshipName=#{relationshipName}"

    describeNestedObject objectType, relationshipName, (err, so) ->
      return handleError(err) if err
      describeFields so.name, parentFields, (err, fields) ->
        return handleError(err) if err
        handleFields(fields)
  else # root query
    objectType = selectNode.find('ObjectType')?.value
    describeFields objectType, parentFields, (err, fields) ->
      return handleError(err) if err
      handleFields(fields)


###
###
describeNestedObject = (objectType, relationshipName, callback) ->
  console.log "describeNestedObject ( #{objectType}, [ #{parentFields.join(',')} ] )"
  getConnection().describeSObject objectType, (err, res) ->
    return callback(err) if err
    childObjectType = null
    for r in res.childRelationships ? []
      if r.relationshipName == relationshipName
        childObjectType = r.childSObject
        break
    return handleError(err)
    getConnection().describeSObject childObjectType, (err, res) ->
      return handleError(err) if err

###
###
describeFields = (objectType, parentFields, callback) ->
  console.log "describeFields ( #{objectType}, [ #{parentFields.join(',')} ] )"
  getConnection().describeSObject objectType, (err, res) ->
    return callback(err) if err
    if parentFields.length > 0
      parentField = parentFields[0]
      parentObjectType = null
      for field in res.fields
        if field.relationshipName == parentField
          refs = field.referenceTo
          refs = if typeof refs == 'string' then [ refs ] else refs
          parentObjectType = if refs.length == 1 then refs[0] else 'Name'
          break
      if parentObjectType
        describeFields(parentObjectType, parentFields.slice(1), callback)
      else
        callback(message: "No reference field name for '#{parentField}'")
    else
      callback(null, res.fields)

###
###
getConnection = ->
  throw new Error("No connection assigned") unless exports.connection
  exports.connection

###
###
debugTokens = (tokens) ->
  console.log (token[1]+"("+token[0]+":"+token[3]+")" for token in tokens).join(' ')


exports.connection = null

exports.tokenize = tokenize
exports.parse    = parse
exports.complete = complete

