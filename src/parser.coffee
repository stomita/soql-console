###
# parser.coffee
###

Node = require './node'

#
#
#
buildParser = ->
  parser = require('./compiled_parser').parser

  parser.lexer =
    lex: ->
      [tag, @yytext, @yylineno] = @tokens[@pos++] or ['']
      tag
    setInput: (@tokens) -> @pos = 0
    upcomingInput: -> ""

  parser.yy = {
    Number: Number
    String: String
    Boolean: Boolean
    Node: Node
    parseError: (e, arg) ->
      err = new Error(e)
      err.expected = arg.expected
      err.pos = @lexer.pos
      throw err
  }
  return parser

exports.parser = buildParser()

exports.parse = (str) -> buildParser().parse(str)
