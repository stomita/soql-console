class Node
  constructor: (@type=null, @value, @children) ->
    if @children?
      for cn in @children
        cn.parent = @ 

  flatten: ->
    if @children?
      arr = []
      for cn in @children
        if cn instanceof Node
          arr.push.apply(arr, cn.flatten()) 
        else
          arr.push(cn)
      arr
    else
      [ @ ]

  print: (depth=0) ->
    lpad = new Array(depth+1).join(' ')
    console.log lpad + "+" + (@type ? '')
    if @children?
      for cn in @children
        if cn instanceof Node
          cn.print(depth+1)
        else
          console.log lpad + " " + cn
    else
      console.log lpad + " " + @value

  find: (type) ->
    if @children
      for cn in @children
        return cn if cn.type == type
      for cn in @children
        n = cn.find(type) if cn instanceof Node
        return n if n?

  findParent: (type) ->
    return null unless @parent 
    if @parent.type == type
      @parent 
    else
      @parent.findParent(type)




#
#
#
buildParser = ->
  parser = require('./compiled_parser').parser

  ###
  # store the current performAction function
  parser._performAction = parser.performAction;
  # override performAction
  parser.performAction = (yytext, yyleng, yylineno, yy, yystate, $$, _$) ->
    # invoke the original performAction
    ret = parser._performAction.apply(parser, arguments)
    # Do your own stuff
    ret
  ###

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
