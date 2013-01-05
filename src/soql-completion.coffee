###
# soql-completion.coffee
###
lexer  = require "./lexer"
parser = require "./parser"
Node   = require "./node"


###
###
asyncMap = (arr, asyncFn, callback) ->
  cnt = arr.length
  rets = new Array(arr.length)
  return callback(rets) if cnt==0
  for a, i in arr
    asyncFn a, (ret) ->
      rets[i] = ret
      cnt--
      return callback(rets) if cnt==0

###
###
complete = (text, caret, callback) ->
  tokens = lexer.tokenize(text)
  { pos, inserting } = findCaretPosition(tokens, caret)
  if inserting
    pos++ if pos < tokens.length - 1
    tokens.splice(pos, 0, [ "UNDEFINED" , "", tokens[pos][3], caret ])
  else
    tokens.splice(pos, 1, [ "UNDEFINED" , "", tokens[pos][2], tokens[pos][3] ])
  # debugTokens tokens
  target = tokens[pos]
  pivot = target[3]
  results = parseTokens(tokens, pos)
  nodes = []
  types = {}
  for n in results
    if typeof n == 'string'
      n = { type: n, value: n}
    else if n.type == 'TERMINAL'
      if n.value
        n = { type: lexer.types[n.value.toUpperCase()] || n.type, value: n.value }
      else
        continue
    unless types[n.type]
      nodes.push(n)
      types[n.type] = true

  asyncMap nodes, (n, cb) ->
    if n.type == 'ObjectType'
      getObjectTypes(n, cb)
    else if n.type == 'FieldName'
      getFieldNames(n, cb)
    else if n.value
      cb([ n ])
    else
      cb([])
  ,
  (rets) ->
    candidates = []
    candidates.push.apply(candidates, ret) for ret in rets
    candidates = candidates.sort (c1, c2) ->
      if c1.type > c2.type then 1 
      else if c1.type < c2.type then -1
      else if c1.value > c2.value then 1
      else if c1.value < c2.value then -1
      else 0
    console.log(candidates)
    callback(candidates, pivot)
  pivot


###
###
parseTokens = (tokens, pos) ->

  tryParse = (tokens, pos, depth=0) ->
    return [] if depth > 5
    try
      tree = parser.parse(tokens)
    catch e
      epos = e.pos - 1
      debugTokens(tokens, pos, epos)
      return [] unless e.expected?
      expected = (name.substring(1, name.length-1) for name in e.expected)
      actual = tokens[epos]
      candidates = []
      etokens = []
      for name in expected
        words = lexer.dictionary[name]
        if words && epos == pos
          candidates.push.apply(candidates, words)
        else
          etokens.push([ name, "", actual[2], actual[3] ])
      if etokens.length > 0
        etokens = etokens.sort (t1, t2) ->
          p1 = lexer.priority(t1[0])
          p2 = lexer.priority(t2[0])
          if p1 < p2 then 1 else if p1 > p2 then -1 else 0
        etoken = etokens[0]
        tkns = Array.prototype.slice.call(tokens)
        replace = if actual[0] == 'UNDEFINED' then 1 else 0
        tkns.splice(epos, replace, etoken)
        inc = if epos < pos then 1 - replace else 0
        candidates.push.apply(candidates, tryParse(tkns, pos+inc, depth+1))
      return candidates

    # tree.print()
    leafs = tree.flatten()
    return [ leafs[pos] ]

  tryParse(tokens, pos)


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
        (caret == tpos + tlen && /^(DOT|SEPARATOR|LEFT_PAREN|RIGHT_PAREN)$/.test(ttag))
      return { pos: i, inserting: inserting }
  { pos: tokens.length-1, inserting: true }

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
    objectType = outerSelectNode.find('ObjectType', selectTypeRegexp)?.value
    getConnection().describeSObject objectType, (err, res) ->
      return handleError(err) if err
      candidates =
        for r in res.childRelationships ? [] when r.relationshipName?
          {
            type: 'childRelationship'
            label: r.relationshipName
            value: r.relationshipName
          }
      callback(candidates)
  else # root query
    getConnection().describeGlobal (err, res) ->
      return handleError(err) if err
      candidates =
        for s in res.sobjects when String(s.queryable) == "true"
          {
            type: 'object'
            label: s.label
            value: s.name
          }
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
          if field.relationshipName
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
    objectType = outerSelectNode.find('ObjectType', selectTypeRegexp)?.value
    relationshipName = selectNode.find('ObjectType', selectTypeRegexp)?.value
    describeNestedObject objectType, relationshipName, (err, so) ->
      return handleError(err) if err
      describeFields so.name, parentFields, (err, fields) ->
        return handleError(err) if err
        handleFields(fields)
  else # root query
    objectType = selectNode.find('ObjectType', selectTypeRegexp)?.value
    describeFields objectType, parentFields, (err, fields) ->
      return handleError(err) if err
      handleFields(fields)


###
###
describeNestedObject = (objectType, relationshipName, callback) ->
  getConnection().describeSObject objectType, (err, res) ->
    return callback(err) if err
    childObjectType = null
    for r in res.childRelationships ? []
      if r.relationshipName == relationshipName
        childObjectType = r.childSObject
        break
    getConnection().describeSObject childObjectType, (err, res) ->
      return callback(err) if err
      callback(null, res)

###
###
describeFields = (objectType, parentFields, callback) ->
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
debugTokens = (tokens, pos, epos) ->
  console.log ("#{token[1]}(#{token[0]}:#{token[3]})#{if pos==i then '*' else ''}#{if epos==i then '!' else ''}" for token, i in tokens).join(' ')


exports.connection = null

exports.complete = complete

