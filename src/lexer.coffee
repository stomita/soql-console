###
# lexer.coffee
###
class Lexer
  constructor: (soql, opts={}) ->
    @soql = soql
    @preserveWhitespace = opts.preserveWhitespace || false
    @tokens = []
    @currentLine = 1
    @index = 0
    while @chunk = soql.slice(@index)
      bytesConsumed =  @keywordToken() or
                       @booleanToken() or
                       @functionToken() or
                       @windowExtension() or
                       @sortOrderToken() or
                       @seperatorToken() or
                       @operatorToken() or
                       @mathToken() or
                       @dotToken() or
                       @conditionalToken() or
                       @numberToken() or
                       @stringToken() or
                       @parensToken() or
                       @whitespaceToken() or
                       @literalToken()
      throw new Error("NOTHING CONSUMED: Stopped at - '#{@chunk.slice(0,30)}'") if bytesConsumed < 1
      @index += bytesConsumed
    @token('EOF', '')
  
  token: (name, value) ->
    @tokens.push([name, value, @currentLine, @index])
  
  tokenizeFromRegex: (name, regex, part=0, lengthPart=part, output=true) ->
    return 0 unless match = regex.exec(@chunk)
    partMatch = match[part]
    @token(name, partMatch) if output
    return match[lengthPart].length
    
  tokenizeFromWord: (name, word=name) ->
    word = @regexEscape(word)
    matcher = if (/^\w+$/).test(word)
      new RegExp("^(#{word})\\b",'ig')
    else
      new RegExp("^(#{word})",'ig')
    match = matcher.exec(@chunk)
    return 0 unless match
    @token(name, match[1])
    return match[1].length
  
  tokenizeFromList: (name, list) ->
    ret = 0
    for entry in list
      ret = @tokenizeFromWord(name, entry)
      break if ret > 0
    ret
  
  keywordToken: ->
    @tokenizeFromWord('SELECT') or
    @tokenizeFromWord('FROM') or
    @tokenizeFromWord('WHERE') or
    @tokenizeFromRegex('GROUP_BY', /^(GROUP\s+BY)/i) or
    @tokenizeFromRegex('ORDER_BY', /^(ORDER\s+BY)/i) or
    @tokenizeFromWord('HAVING') or
    @tokenizeFromWord('LIMIT') or
    @tokenizeFromWord('OFFSET') or
    @tokenizeFromWord('AS')
  
  dotToken: -> @tokenizeFromWord('DOT', '.')
  operatorToken:    -> @tokenizeFromList('OPERATOR', SOQL_OPERATORS)
  mathToken:        ->
    @tokenizeFromList('MATH', MATH) or
    @tokenizeFromList('MATH_MULTI', MATH_MULTI)
  conditionalToken: -> @tokenizeFromList('CONDITIONAL', SOQL_CONDITIONALS)
  functionToken:    -> @tokenizeFromList('FUNCTION', SOQL_FUNCTIONS)
  sortOrderToken:   -> @tokenizeFromList('DIRECTION', SOQL_SORT_ORDERS)
  booleanToken:     -> @tokenizeFromList('BOOLEAN', BOOLEAN)
  seperatorToken:   -> @tokenizeFromRegex('SEPARATOR', SEPARATOR)
  literalToken:     -> @tokenizeFromRegex('LITERAL', LITERAL, 1, 0)
  numberToken:      -> @tokenizeFromRegex('NUMBER', NUMBER)
  stringToken:      ->
    @tokenizeFromRegex('STRING', STRING, 1, 0) ||
    @tokenizeFromRegex('DBLSTRING', DBLSTRING, 1, 0)
    
    
  parensToken: ->
    @tokenizeFromRegex('LEFT_PAREN', /^\(/,) or
    @tokenizeFromRegex('RIGHT_PAREN', /^\)/,)
  
  windowExtension: ->
    match = (/^\.(win):(length|time)/i).exec(@chunk)
    return 0 unless match
    @token('WINDOW', match[1])
    @token('WINDOW_FUNCTION', match[2])
    match[0].length
  
  whitespaceToken: ->
    return 0 unless match = WHITESPACE.exec(@chunk)
    partMatch = match[0]
    newlines = partMatch.replace(/[^\n]/, '').length
    @currentLine += newlines
    @token(name, partMatch) if @preserveWhitespace
    return partMatch.length
  
  regexEscape: (str) ->
    str.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&")
  
SOQL_KEYWORDS        = ['SELECT', 'FROM', 'WHERE', 'GROUP BY', 'ORDER BY', 'HAVING', 'LIMIT', 'OFFSET', 'AS']
SOQL_FUNCTIONS       = ['AVG', 'COUNT', 'MIN', 'MAX', 'SUM']
SOQL_SORT_ORDERS     = ['ASC', 'DESC']
SOQL_OPERATORS       = ['=', '!=', '>', '<', '<=', '>=', 'LIKE', 'IS NOT', 'IS', 'IN']
SOQL_CONDITIONALS    = ['AND', 'OR', 'NOT']
BOOLEAN              = ['true', 'false', 'null']
MATH                 = ['+', '-']
MATH_MULTI           = ['/', '*']
SEPARATOR            = /^,/
WHITESPACE           = /^[ \n\r]+/
LITERAL              = /^`?([a-z_][a-z0-9_]{0,})`?/i
NUMBER               = /^[0-9]+(\.[0-9]+)?/
STRING               = /^'([^\\']*(?:\\.[^\\']*)*)'/
DBLSTRING            = /^"([^\\"]*(?:\\.[^\\"]*)*)"/

  
exports.tokenize = (soql, opts) -> (new Lexer(soql, opts)).tokens

exports.dictionary =
  FUNCTION  : SOQL_FUNCTIONS
  DIRECTION : SOQL_SORT_ORDERS
  OPERATOR  : SOQL_OPERATORS
  CONDITIONAL  : SOQL_CONDITIONALS
  SEPARATOR    : [ ',' ]
  DOT          : [ '.' ]
  LEFT_PAREN   : [ '(' ]
  RIGHT_PAREN  : [ ')' ]

exports.dictionary[keyword.replace(/\s+/g, '_')] = [ keyword ] for keyword in SOQL_KEYWORDS

exports.examples =
  LITERAL : 'A'
  NUMBER  : '1'
  STRING  : "'A'"
  BOOLEAN : 'true'

exports.priority = {}
exports.priority[name] = 1 for name in SOQL_KEYWORDS
exports.priority[name] = 2 for name, value of exports.examples

