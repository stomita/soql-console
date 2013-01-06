###
# lexer_test.coffee
###
expect = require 'expect.js'

Node   = require '../src/node'
lexer  = require '../src/lexer'

###
###
describe "tokenizing SOQL input", ->
  ###
  ###
  soql = "SELECT Id, Name, Account.Name FROM Name WHERE Name LIKE 'ABC%' LIMIT 10"
  tokens = null

  ###
  ###
  before ->
    tokens = lexer.tokenize(soql)

  ###
  ###
  it "should get array of token", ->
    expect(tokens).to.be.an('array')
    expect(tokens).to.have.length(17)

  it "should get tokens by array and each of token's length is 4", ->
    for token in tokens
      expect(token).to.be.an('array')
      expect(token).to.have.length(4)

  it "should get SELECT tag in its start, and EOF tag in its end", ->
    expect(tokens[0][0]).to.equal("SELECT")
    expect(tokens[tokens.length-1][0]).to.equal("EOF")

###
###
describe "tokenizing invalid input in syntax", ->
  soql = "FROM SELECT Id, , LIKE IN 4 'ABC').WHERE >LIMIT 10.0"
  tokens =  null
  expectedTokens = [
    [ "FROM",        "FROM",   1, 0 ]
    [ "SELECT",      "SELECT", 1, 5 ]
    [ "LITERAL",     "Id",     1, 12 ]
    [ "SEPARATOR",   ",",      1, 14 ]
    [ "SEPARATOR",   ",",      1, 16 ]
    [ "COMP_OPERATOR", "LIKE", 1, 18 ]
    [ "COMP_OPERATOR", "IN",   1, 23 ]
    [ "NUMBER",      "4",      1, 26 ]
    [ "STRING",      "ABC",    1, 28 ]
    [ "RIGHT_PAREN", ")",      1, 33 ]
    [ "DOT",         ".",      1, 34 ]
    [ "WHERE",       "WHERE",  1, 35 ]
    [ "COMP_OPERATOR", ">",    1, 41 ]
    [ "LIMIT",       "LIMIT",  1, 42 ]
    [ "NUMBER",      "10.0",   1, 48 ]
    [ "EOF",         "",       1, 52 ]
  ]

  ###
  ###
  before ->
    tokens = lexer.tokenize(soql)

  ###
  ###
  it "should get array of token", ->
    expect(tokens).to.be.an('array')
    expect(tokens).to.have.length(expectedTokens.length)

  it "should get expected tokens", ->
    for token, i in tokens
      expect(token).to.be.an('array')
      expect(token).to.have.length(4)
      expected = expectedTokens[i]
      expect(token).to.eql(expected)

###
###
describe 'tokenizating invalid input in lex', ->
  ###
  ###
  soql = "SELECT Id, \"AAA' FROM A WHERE AA<2"

  ###
  ###
  it "should fail tokenizing string", ->
    expect ->
      lexer.tokenize(soql)
    .to.throwException()

