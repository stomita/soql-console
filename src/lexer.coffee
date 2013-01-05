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
    @tokenizeFromRegex('NULLS_FIRST', /^(NULLS\s+FIRST)/i) or
    @tokenizeFromRegex('NULLS_LAST', /^(NULLS\s+LAST)/i)

  dotToken: -> @tokenizeFromWord('DOT', '.')
  operatorToken:    -> @tokenizeFromList('OPERATOR', OPERATORS)
  mathToken:        ->
    @tokenizeFromList('MATH', MATH) or
    @tokenizeFromList('MATH_MULTI', MATH_MULTI)
  conditionalToken: -> @tokenizeFromList('CONDITIONAL', CONDITIONALS)
  functionToken:    -> @tokenizeFromList('FUNCTION', FUNCTIONS)
  sortOrderToken:   -> @tokenizeFromList('DIRECTION', SORT_ORDERS)
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
  
KEYWORDS        = ['SELECT', 'FROM', 'WHERE', 'GROUP BY', 'ORDER BY', 'HAVING', 'LIMIT', 'OFFSET', 'NULLS FIRST', 'NULLS LAST']
FUNCTIONS       = ['AVG', 'COUNT', 'COUNT_DISTINCT', 'MIN', 'MAX', 'SUM']
DATE_FUNCTIONS  = []
SORT_ORDERS     = ['ASC', 'DESC']
OPERATORS       = ['=', '!=', '>', '<', '<=', '>=', 'LIKE', 'IS NOT', 'IS', 'IN']
CONDITIONALS    = ['AND', 'OR', 'NOT']
BOOLEAN         = ['true', 'false', 'null']
MATH            = ['+', '-']
MATH_MULTI      = ['/', '*']
SEPARATOR       = /^,/
WHITESPACE      = /^[ \n\r]+/
LITERAL         = /^`?([a-z_][a-z0-9_]{0,})`?/i
NUMBER          = /^[0-9]+(\.[0-9]+)?/
STRING          = /^'([^\\']*(?:\\.[^\\']*)*)'/
DBLSTRING       = /^"([^\\"]*(?:\\.[^\\"]*)*)"/

  
exports.tokenize = (soql, opts) -> (new Lexer(soql, opts)).tokens

exports.dictionary =
  FUNCTION  : FUNCTIONS.concat(DATE_FUNCTIONS)
  DIRECTION : SORT_ORDERS
  OPERATOR  : OPERATORS
  CONDITIONAL : CONDITIONALS

exports.dictionary[keyword.replace(/\s+/g, '_')] = [ keyword ] for keyword in KEYWORDS

exports.types = do ->
  types = {}
  for type, names of exports.dictionary
    types[name] = type for name in names
  types

exports.priority = (name) ->
  type = exports.types[name.toUpperCase()] || name
  switch type
    when 'KEYWORD', 'DIRECTION', 'OPERATOR' then 3
    when 'LITERAL' then 2
    when 'FUNCTION' then 1
    else 0
