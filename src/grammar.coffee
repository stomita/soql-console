{Parser} = require "jison"

unwrap = /^function\s*\(\)\s*\{\s*return\s*([\s\S]*);\s*\}/

o = (patternString, action) ->
  (symbol) ->


grammar =

  Root: [
    'Query EOF'
  ]

  Query: [
    'SelectQuery'
    'SelectQuery LimitClause'
    'SelectQuery LimitClause OffsetClause'
  ]

  SelectQuery: [
    'Select'
    'Select OrderClause'
    'Select GroupClause'
    'Select GroupClause OrderClause'
  ]

  InnerSelect : [
    'Select'
    'Select LimitClause'
    'Select OrderClause'
    'Select OrderClause LimitClause'
  ]

  Select : [
    'SelectClause'
    'SelectClause WhereClause'
  ]

  SelectClause: [
    'SELECT SelectFieldList FROM Object'
    'SELECT COUNT LEFT_PAREN RIGHT_PAREN FROM Object'
  ]

  SelectFieldList: [
    'SelectField'
    'SelectField SEPARATOR SelectFieldList'
  ]

  SelectField: [
    'Field'
    'Function LEFT_PAREN FieldList RIGHT_PAREN'
    'LEFT_PAREN InnerSelect RIGHT_PAREN'
  ]

  Object: [
    'ObjectType'
    'ObjectType Alias'
  ]

  ObjectType: [
    'Literal'
  ]

  Alias: [
    'Literal'
  ]

  WhereClause: [
    'WHERE ConditionExpressionList'
  ]

  LimitClause: [
    'LIMIT Number'
  ]

  OffsetClause: [
    'OFFSET Number'
  ]

  OrderClause: [
    'ORDER_BY OrderArgList'
  ]

  OrderArgList: [
    'OrderArg'
    'OrderArg SEPARATOR OrderArgList'
  ]

  OrderArg: [
    'OrderField'
    'OrderField DIRECTION'
    'OrderField DIRECTION NullPolicy'
  ]

  NullPolicy: [
    'NULLS_FIRST'
    'NULLS_LAST'
  ]

  OrderField: [
    'Field'
    'Function LEFT_PAREN Field RIGHT_PAREN'
  ]

  GroupClause: [
    'GroupBasicClause'
    'GroupBasicClause HavingClause'
  ]

  GroupBasicClause: [
    'GROUP_BY GroupByFieldList'
    'GROUP_BY GroupByFieldList'
  ]

  GroupByFieldList: [
    'GroupByField'
    'GroupByField SEPARATOR GroupByFieldList'
  ]

  GroupByField: [
    'Field'
    'Function LEFT_PAREN Field RIGHT_PAREN'
  ]

  Function: [
    'FUNCTION'
  ]

  HavingClause: [
    'HAVING ConditionExpressionList'
  ]

  ConditionExpressionList: [
    'ConditionExpression'
    'ConditionExpression CONDITIONAL ConditionExpressionList'
    'LEFT_PAREN ConditionExpressionList RIGHT_PAREN'
  ]

  ConditionExpression: [
    'ConditionField OPERATOR Value'
  ]

  ConditionField: [
    'Field'
    'Function LEFT_PAREN FunctionArgList RIGHT_PAREN'
  ]

  FunctionArgList: [
    'FunctionArg'
    'FunctionArg SEPARATOR FunctionArgList'
  ]

  FunctionArg: [
    'Field'
    'Value'
  ]

  FieldList: [
    'Field'
    'Field SEPARATOR FieldList'
  ]

  Field: [
    'FieldName'
    'FieldName DOT Field'
  ]

  FieldName: [
    'Literal'
  ]

  Value: [
    'Number'
    'String'
    'Boolean'
  ]

  Number: [
    [ 'NUMBER',    -> Number($1) ]
  ]

  Boolean: [
    [ 'BOOLEAN',   -> Boolean($1) ]
  ]

  String: [
    [ 'STRING',    -> String($1) ]
  ]

  Literal: [
    [ 'LITERAL',   -> $1 ]
  ]


operators = [
  ['left', 'Op']
  ['left', 'OPERATOR']
  ['left', 'CONDITIONAL']
]

tokens = {}

for name, alternatives of grammar
  grammar[name] = for alt, index in alternatives
    if alt instanceof Array
      [ pattern, action ] = alt
    else
      pattern = alt
      action = null
    for token in pattern.split /\s+/
      tokens[token] = token unless grammar[token]
    if action?
      action = if m = unwrap.exec action then m[1] else "(#{action}())"
      action = "$$ = #{action};"
    else
      num = pattern.split(/\s/).length
      args = ('$'+i for i in [1..num]).join(', ')
      action = "$$ = new yy.Node({ type: '#{name}', childNodes: [ #{args} ] });"
    action = "return #{action}" if name is 'Root'
    [ pattern, action ]

###
for name, alternatives of grammar
  grammar[name] = for alt in alternatives
    for token in alt[0].split ' '
      tokens[token] = token unless grammar[token]
    alt[1] = "return #{alt[1]}" if name is 'Root'
    alt
###

exports.parser = new Parser
#  lex         : lex
  tokens      : (name for name of tokens).join ' '
  bnf         : grammar
  operators   : operators.reverse()
  startSymbol : 'Root'
,
  type: 'lr'
