###
# lexer.coffee
#
# Copyright 2012, Shinichi Tomita <shinichi.tomita@gmail.com>
#
# Based on SQL Parser
# https://github.com/forward/sql-parser
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
                       @sortOrderToken() or
                       @seperatorToken() or
                       @compOpToken() or
                       @mathToken() or
                       @dotToken() or
                       @logicOpToken() or
                       @dateLiteralToken() or
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
  compOpToken:    -> @tokenizeFromList('COMP_OPERATOR', COMP_OPERATORS)
  mathToken:        ->
    @tokenizeFromList('MATH', MATH) or
    @tokenizeFromList('MATH_MULTI', MATH_MULTI)
  logicOpToken: -> @tokenizeFromList('LOGIC_OPERATOR', LOGIC_OPERATORS)
  functionToken:    ->
    @tokenizeFromList('AGGR_FUNCTION', AGGR_FUNCTIONS) or
    @tokenizeFromList('DATE_FUNCTION', DATE_FUNCTIONS)
  sortOrderToken:   -> @tokenizeFromList('DIRECTION', SORT_ORDERS)
  booleanToken:     -> @tokenizeFromList('BOOLEAN', BOOLEAN)
  seperatorToken:   -> @tokenizeFromRegex('SEPARATOR', SEPARATOR)
  literalToken:     -> @tokenizeFromRegex('LITERAL', LITERAL, 1, 0)
  dateLiteralToken: ->
    @tokenizeFromRegex('DATE_LITERAL', DATE_LITERAL) or
    @tokenizeFromRegex('DATE_LITERAL', RESERVED_DATE_LITERAL)
  numberToken:      -> @tokenizeFromRegex('NUMBER', NUMBER)
  stringToken:      ->
    @tokenizeFromRegex('STRING', STRING, 1, 0) ||
    @tokenizeFromRegex('DBLSTRING', DBLSTRING, 1, 0)

    
  parensToken: ->
    @tokenizeFromRegex('LEFT_PAREN', /^\(/,) or
    @tokenizeFromRegex('RIGHT_PAREN', /^\)/,)
  
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
AGGR_FUNCTIONS  = ['AVG', 'COUNT', 'COUNT_DISTINCT', 'MIN', 'MAX', 'SUM']
DATE_FUNCTIONS  = ['CALENDAR_MONTH', 'CALENDAR_QUARTER', 'CALENDAR_YEAR', 'DAY_IN_MONTH', 'DAY_IN_WEEK', 'DAY_IN_YEAR', 'DAY_ONLY', 'FISCAL_MONTH', 'FISCAL_QUARTER', 'FISCAL_YEAR', 'HOUR_IN_DAY', 'WEEK_IN_MONTH', 'WEEK_IN_YEAR']
SORT_ORDERS     = ['ASC', 'DESC']
COMP_OPERATORS  = ['=', '!=', '>', '<', '<=', '>=', 'LIKE', 'IN', 'NOT IN', 'INCLUDES', 'EXCLUDES']
LOGIC_OPERATORS = ['AND', 'OR', 'NOT']
BOOLEAN         = ['true', 'false', 'null']
MATH            = ['+', '-']
MATH_MULTI      = ['/', '*']
SEPARATOR       = /^,/
WHITESPACE      = /^[ \n\r]+/
LITERAL         = /^`?([a-z_][a-z0-9_]{0,})`?/i
DATE_LITERAL    = /^([\d]{4})-([\d]{2})-([\d]{2})(T([\d]{2}):([\d]{2}):([\d]{2})(.([\d]{3}))?(Z|([\+\-])([\d]{2}):([\d]{2})))?/
RESERVED_DATE_LITERAL =
  /^(YESTERDAY|TODAY|TOMORROW|(LAST|THIS|NEXT)_(WEEK|MONTH|(FISCAL_)?(QUARTER|YEAR))|(LAST|NEXT)_(90_DAYS|N_(DAYS|(FISCAL_)?(QUARTERS|YEARS):\d+)))/i
NUMBER          = /^[0-9]+(\.[0-9]+)?/
STRING          = /^'([^\\']*(?:\\.[^\\']*)*)'/
DBLSTRING       = /^"([^\\"]*(?:\\.[^\\"]*)*)"/

  
exports.tokenize = (soql, opts) -> (new Lexer(soql, opts)).tokens

exports.dictionary =
  AGGR_FUNCTION: AGGR_FUNCTIONS
  DATE_FUNCTION: DATE_FUNCTIONS
  DIRECTION : SORT_ORDERS
  COMP_OPERATOR : COMP_OPERATORS
  LOGIC_OPERATOR : LOGIC_OPERATORS 

exports.dictionary[keyword.replace(/\s+/g, '_')] = [ keyword ] for keyword in KEYWORDS

exports.types = do ->
  types = {}
  types[name] = 'function' for name in AGGR_FUNCTIONS.concat(DATE_FUNCTIONS)
  types[name] = 'direction' for name in SORT_ORDERS
  types[name] = 'keyword' for name in KEYWORDS
  types[name] = 'operator' for name in COMP_OPERATORS
  types[name] = 'logical' for name in LOGIC_OPERATORS
  types

exports.priority = (name) ->
  type = exports.types[name.toUpperCase()] || name
  switch type
    when 'keyword', 'direction', 'operator' then 3
    when 'LITERAL' then 2
    when 'function' then 1
    else 0
