{Parser} = require "jison"

unwrap = /^function\s*\(\)\s*\{\s*return\s*([\s\S]*);\s*\}/

o = (patternString, type, action) ->
  patternString = patternString.replace /\s{2,}/g, ' '
  num = patternString.split(/\s/).length
  args = ('$'+i for i in [1..num]).join(', ')
  if num == 1
    if type?
      action = "$$ = new yy.Node('#{type}', $1);"
    else
      action = "$$ = $1;"
  else
    type = type ? ''
    action = "$$ = new yy.Node('#{type}', null, [ #{args} ]);"
  [ patternString, action, undefined ]

grammar =
  Root: [
    o 'Query EOF'
  ]

  Query: [
    o 'SelectQuery'
    o 'SelectQuery LimitClause'
    o 'SelectQuery LimitClause OffsetClause'
  ]

  SelectQuery: [
    o 'Select'
    o 'Select OrderClause'
    o 'Select GroupClause'
    o 'Select GroupClause OrderClause'
  ]

  Select : [
    o 'SelectClause'
    o 'SelectClause WhereClause'
  ]

  InnerSelect : [
    o 'SelectClause'
    o 'SelectClause WhereClause'
    o 'SelectClause WhereClause LimitClause'
  ]

  SelectClause: [
    o 'SELECT SelectFieldList FROM ObjectType'
  ]

  SelectFieldList: [
    o 'SelectField'
    o 'SelectField SEPARATOR SelectFieldList'
  ]

  SelectField: [
    o 'Field'
    o 'Field AS Literal'
    o 'LEFT_PAREN InnerSelect RIGHT_PAREN'
  ]

  ObjectType: [
    o 'Literal',  'ObjectType'
  ]

  WhereClause: [
    o 'WHERE ConditionExpressionList'
  ]

  LimitClause: [
    o 'LIMIT Number'
  ]

  OffsetClause: [
    o 'OFFSET Number'
  ]

  OrderClause: [
    o 'ORDER_BY OrderArgList'
  ]

  OrderArgList: [
    o 'OrderArg'
    o 'OrderArg SEPARATOR OrderArgList'
  ]

  OrderArg: [
    o 'Field'
    o 'Field DIRECTION'
  ]

  GroupClause: [
    o 'GroupBasicClause'
    o 'GroupBasicClause HavingClause'
  ]

  GroupBasicClause: [
    o 'GROUP_BY FieldList'
  ]

  HavingClause: [
    o 'HAVING ConditionExpressionList'
  ]

  ConditionExpressionList: [
    o 'ConditionExpression'
    o 'ConditionExpression CONDITIONAL ConditionExpressionList'
    o 'LEFT_PAREN ConditionExpressionList RIGHT_PAREN'
  ]

  ConditionExpression: [
    o 'Field OPERATOR Value'
  ]

  FieldList: [
    o 'Field'
    o 'Field SEPARATOR FieldList'
  ]

  Field: [
    o 'FieldName'
    o 'FieldName DOT Field'
  ]

  FieldName: [
    o 'Literal', 'FieldName'
  ]

  Value: [
    o 'NUMBER'
    o 'String'
    o 'Boolean'
  ]

  Number: [
    o 'NUMBER'
  ]

  Boolean: [
    o 'BOOLEAN'
  ]

  String: [
    o 'STRING'
  ]

  Literal: [
    o 'LITERAL'
  ]


tokens = []
operators = [
  ['left', 'Op']
  ['left', 'OPERATOR']
  ['left', 'CONDITIONAL']
]

for name, alternatives of grammar
  grammar[name] = for alt in alternatives
    for token in alt[0].split ' '
      tokens.push token unless grammar[token]
    alt[1] = "return #{alt[1]}" if name is 'Root'
    alt

exports.parser = new Parser
#  lex         : lex
  tokens      : tokens.join ' '
  bnf         : grammar
  operators   : operators.reverse()
  startSymbol : 'Root'
,
  type: 'lr'
