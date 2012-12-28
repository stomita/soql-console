expect = require 'expect.js'

Node   = require '../build/node'
SoqlCompletion = require '../build/soql-completion'


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
    tokens = SoqlCompletion.tokenize(soql)

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
    [ "OPERATOR",    "LIKE",   1, 18 ]
    [ "OPERATOR",    "IN",     1, 23 ]
    [ "NUMBER",      "4",      1, 26 ]
    [ "STRING",      "ABC",    1, 28 ]
    [ "RIGHT_PAREN", ")",      1, 33 ]
    [ "DOT",         ".",      1, 34 ]
    [ "WHERE",       "WHERE",  1, 35 ]
    [ "OPERATOR",    ">",      1, 41 ]
    [ "LIMIT",       "LIMIT",  1, 42 ]
    [ "NUMBER",      "10.0",   1, 48 ]
    [ "EOF",         "",       1, 52 ]
  ]

  ###
  ###
  before ->
    tokens = SoqlCompletion.tokenize(soql)

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
      SoqlCompletion.tokenize(soql)
    .to.throwException()

###
###
describe "parsing soql", ->
  ###
  ###
  soql = """
    SELECT Id, Parent.Owner.Name,
      (SELECT Name FROM Contacts
       WHERE Owner.Name LIKE 'A%')
    FROM Account
    WHERE NumOfEmployees>100 AND Owner.Id = '0000000'
    ORDER BY CreatedDate DESC, Owner.Name ASC
    LIMIT 10
  """
  tokens = null
  tree = null
  leafs = null

  before ->
    tokens = SoqlCompletion.tokenize(soql)
    tree = SoqlCompletion.parse(tokens)
    # tree.print()

  ###
  ###
  it "should get a syntax tree", ->
    expect(tree).to.be.a(Node)

  it "should get tree leafs corresponding to parsed tokens", ->
    leafs = tree.flatten()
    expect(leafs).to.be.an('array')
    expect(leafs).to.have.length(tokens.length)

  ###
  ###
  describe "traversing tree", ->
    ###
    ###
    selectTypeRegexp = /^(SelectQuery|InnerSelect)$/
    node = null

    ###
    ###
    describe "field 'SELECT [Id], ...'", ->

      it "should get a node of field", ->
        node = leafs[1] # Id
        expect(node).to.be.a(Node)
        expect(node.value).to.equal('Id')
        expect(node.type).to.equal('FieldName')

      it "should be in select clause", ->
        node = node.findParent(selectTypeRegexp)
        expect(node).to.be.a(Node)
        expect(node.type).to.match(selectTypeRegexp)

      it "should find related object type node with value 'Account'", ->
        node = node.find('ObjectType')
        expect(node).to.be.a(Node)
        expect(node.type).to.equal('ObjectType')
        expect(node.value).to.equal('Account')

    ###
    ###
    describe "field ' Parent.Owner.[Name], ...'", ->

      nullNode = null

      it "should get a node of field", ->
        node = leafs[7] # Parent.Owner.[Name]
        expect(node).to.be.a(Node)
        expect(node.value).to.equal('Name')
        expect(node.type).to.equal('FieldName')

      it "should find parent field (Parent.[Owner].Name)", ->
        node = node.findPrevious('FieldName', 'SelectField') # Parent.[Owner].Name
        expect(node).to.be.a(Node)
        expect(node.type).to.equal('FieldName')
        expect(node.value).to.equal('Owner')

      it "should find grand parent field ([Parent].Owner.Name)", ->
        node = node.findPrevious('FieldName', 'SelectField') # [Parent].Owner.Name
        expect(node).to.be.a(Node)
        expect(node.type).to.equal('FieldName')
        expect(node.value).to.equal('Parent')

      it "should not have further ancestor field any more", ->
        nullNode = node.findPrevious('FieldName', 'SelectField')
        expect(nullNode).to.be(null)

    ###
    ###
    describe "field '(SELECT [Name] FROM Contacts'", ->
      innerSelectNode = null

      it "should get a node of field", ->
        node = leafs[11] # (SELECT [Name] FROM Contacts)
        expect(node).to.be.a(Node)
        expect(node.value).to.equal('Name')
        expect(node.type).to.equal('FieldName')

      it "should be in select clause", ->
        node = node.findParent(selectTypeRegexp)
        expect(node).to.be.a(Node)
        expect(node.type).to.match(selectTypeRegexp)
        innerSelectNode  = node

      it "should find related object type node with value 'Contacts'", ->
        node = innerSelectNode.find('ObjectType')
        expect(node).to.be.a(Node)
        expect(node.type).to.equal('ObjectType')
        expect(node.value).to.equal('Contacts')

      it "should have outer select clause", ->
        node = innerSelectNode.findParent(selectTypeRegexp)
        expect(node).to.be.a(Node)
        expect(node.type).to.match(selectTypeRegexp)

      it "should find related object type node with value 'Account'", ->
        node = node.find('ObjectType')
        expect(node).to.be.a(Node)
        expect(node.type).to.equal('ObjectType')
        expect(node.value).to.equal('Account')


    ###
    ###
    describe "field ' WHERE Owner.[Name] LIKE 'A%' ...'", ->
      nullNode = null

      it "should get a node of field", ->
        node = leafs[17] # (WHERE Owner.[Name] LIKE 'A%')
        expect(node).to.be.a(Node)
        expect(node.value).to.equal('Name')
        expect(node.type).to.equal('FieldName')

      it "should find parent field (WHERE [Owner].Name LIKE)", ->
        node = node.findPrevious('FieldName', 'SelectField') # [Owner].Name
        expect(node).to.be.a(Node)
        expect(node.type).to.equal('FieldName')
        expect(node.value).to.equal('Owner')

      it "should not have further ancestor field any more", ->
        nullNode = node.findPrevious('FieldName', 'SelectField')
        expect(nullNode).to.be(null)

      it "should be in select clause", ->
        node = node.findParent(selectTypeRegexp)
        expect(node).to.be.a(Node)
        expect(node.type).to.match(selectTypeRegexp)

      it "should find related object type node with value 'Contacts'", ->
        node = node.find('ObjectType')
        expect(node).to.be.a(Node)
        expect(node.type).to.equal('ObjectType')
        expect(node.value).to.equal('Contacts')

    ###
    ###
    describe "field ' WHERE [NumOfEmployees] > 100 ...'", ->
      nullNode = null

      it "should get a node of field", ->
        node = leafs[24] # (WHERE [NumOfEmployees] > 100)
        expect(node).to.be.a(Node)
        expect(node.value).to.equal('NumOfEmployees')
        expect(node.type).to.equal('FieldName')

      it "should not have parent field", ->
        nullNode = node.findPrevious('FieldName', 'SelectField')
        expect(nullNode).to.be(null)

      it "should be in select clause", ->
        node = node.findParent(selectTypeRegexp)
        expect(node).to.be.a(Node)
        expect(node.type).to.match(selectTypeRegexp)

      it "should find related object type node with value 'Account'", ->
        node = node.find('ObjectType')
        expect(node).to.be.a(Node)
        expect(node.type).to.equal('ObjectType')
        expect(node.value).to.equal('Account')

    ###
    ###
    describe "field ' ORDER BY [CreatedDate] DESC ...'", ->
      it "should get a node of field", ->
        node = leafs[34] # ORDER BY [CreatedDate] DESC
        expect(node).to.be.a(Node)
        expect(node.value).to.equal('CreatedDate')
        expect(node.type).to.equal('FieldName')

      it "should not have parent field", ->
        nullNode = node.findPrevious('FieldName', 'SelectField')
        expect(nullNode).to.be(null)

      it "should be in select clause", ->
        node = node.findParent(selectTypeRegexp)
        expect(node).to.be.a(Node)
        expect(node.type).to.match(selectTypeRegexp)

      it "should find related object type node with value 'Account'", ->
        node = node.find('ObjectType')
        expect(node).to.be.a(Node)
        expect(node.type).to.equal('ObjectType')
        expect(node.value).to.equal('Account')

###
###
describe "completing", ->
  ###
  ###
  cases = [
    input: "SELE|"
    expect: (candidates, index) ->
      expect(candidates).to.have.length(1)
      expect(candidates[0].value).to.equal('SELECT')
      expect(index).to.equal(0)
  ,
    input: "SELECT  FROM |"
    expect: (candidates, index) ->
      expect(candidates.length).to.be.above(0)
      for candidate in candidates
        expect(candidate).to.have.property('type', 'object')
        expect(index).to.equal(@caret)
  ,
    input: "SELECT Id, Na| FROM Account"
    expect: (candidates, index) ->
      expect(candidates.length).to.be.above(0)
      for candidate in candidates
        expect(candidate).to.have.property('type', 'field')
        expect(candidate).to.have.property('fieldType')
      expect(index).to.equal(@caret-2) # SELECT Id, |Na FROM Account
  ]

  ###
  ###
  for cs in cases

    describe "#{cs.desc ? 'input'} (#{cs.input})", ->

      it "should complete expected candidates", (done) ->
        cs.caret = cs.input.indexOf('|')
        cs.soql = cs.input.replace('|', '')
        SoqlCompletion.complete cs.soql, cs.caret, (candidates, index) ->
          expect(candidates).to.be.an('array')
          if cs.expect? 
            cs.expect(candidates, index)
          done()

