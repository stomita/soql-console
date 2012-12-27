###
# soql-completion.coffee
###
lexer  = require "./lexer"
parser = require "./parser"

tokenize = (soql) -> lexer.tokenize(soql)

parse = (tokens) -> parser.parse(tokens)

complete = (text, caretIndex, callback) ->

exports.tokenize = tokenize
exports.parse    = parse
exports.complete = complete

