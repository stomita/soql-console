expect = require 'expect.js'

Node   = require '../build/node'
SoqlCompletion = require '../build/soql-completion'


###
###
describe 'SOQL Completion Test', ->

  ###
  ###
  it "should tokenize valid soql", ->
    soql = "SELECT Id, Name, Account.Name FROM Name WHERE Name LIKE 'ABC%' LIMIT 10"
    tokens = SoqlCompletion.tokenize(soql)

    expect(tokens).to.be.an('array')
    expect(tokens).to.have.length(17)
    expect(tokens[0]).to.be.an('array')
    expect(tokens[0]).to.have.length(4)
    expect(tokens[0][0]).to.equal("SELECT")
    expect(tokens[tokens.length-1][0]).to.equal("EOF")

  ###
  ###
  it "should tokenize invalid soql with valid tokens", ->
    soql = "FROM SELECT Id, , LIKE IN 4 'ABC').WHERE >LIMIT 10.0"
    tokens = SoqlCompletion.tokenize(soql)
    expectedTokens = [
      [ "FROM",        "FROM"   ]
      [ "SELECT",      "SELECT" ]
      [ "LITERAL",     "Id" ]
      [ "SEPARATOR",   "," ]
      [ "SEPARATOR",   "," ]
      [ "OPERATOR",    "LIKE" ]
      [ "OPERATOR",    "IN" ]
      [ "NUMBER",      "4" ]
      [ "STRING",      "ABC" ]
      [ "RIGHT_PAREN", ")" ]
      [ "DOT",         "." ]
      [ "WHERE",       "WHERE" ]
      [ "OPERATOR",    ">" ]
      [ "LIMIT",       "LIMIT" ]
      [ "NUMBER",      "10.0" ]
      [ "EOF",         "" ]
    ]

    expect(tokens).to.be.an('array')
    expect(tokens).to.have.length(expectedTokens.length)
    for token, i in tokens
      expect(token).to.be.an('array')
      expect(token).to.have.length(4)
      expected = expectedTokens[i]
      expect(token[0]).to.equal(expected[0])
      expect(token[1]).to.equal(expected[1])

  ###
  ###
  it "should fail tokenizing string with invalid tokens", ->
    soql = "SELECT Id, \"AAA' FROM A WHERE AA<2"
    expect ->
      SoqlCompletion.tokenize(soql)
    .to.throwException()

  ###
  ###
  it "should parse valid soql into syntax tree", ->
    soql = """
      SELECT Id, Parent.Owner.Name,
        (SELECT Name FROM Contacts
         WHERE Owner.Name LIKE 'A%')
      FROM Account
      WHERE NumOfEmployees>100 AND Owner.Id = '0000000'
      ORDER BY CreatedDate DESC, Owner.Name ASC
      LIMIT 10
    """
    tokens = SoqlCompletion.tokenize(soql)
    expect(tokens).to.be.an('array')
    expect(tokens).to.have.length(44)

    tree = SoqlCompletion.parse(tokens)
    expect(tree).to.be.a(Node)

    # tree.print()

    leafs = tree.flatten()
    expect(leafs).to.be.an('array')
    expect(leafs).to.have.length(tokens.length)

    ### Id field ###
    node = leafs[1] # Id
    expect(node).to.be.a(Node)
    expect(node.value).to.equal('Id')
    expect(node.type).to.equal('FieldName')

    selectTypeRegexp = /^(SelectQuery|InnerSelect)$/

    selectClauseNode = node.findParent(selectTypeRegexp)
    expect(selectClauseNode).to.be.a(Node)
    expect(selectClauseNode.type).to.match(selectTypeRegexp)

    objectTypeNode = selectClauseNode.find('ObjectType')
    expect(objectTypeNode).to.be.a(Node)
    expect(objectTypeNode.type).to.equal('ObjectType')
    expect(objectTypeNode.value).to.equal('Account')

    ### Parent.Owner.[Name] field ###
    node = leafs[7] # Parent.Owner.[Name]
    expect(node).to.be.a(Node)
    expect(node.value).to.equal('Name')
    expect(node.type).to.equal('FieldName')

    ownerFieldNode = node.findPrevious('FieldName', 'SelectField')
    expect(ownerFieldNode).to.be.a(Node)
    expect(ownerFieldNode.type).to.equal('FieldName')
    expect(ownerFieldNode.value).to.equal('Owner')

    parentFieldNode = ownerFieldNode.findPrevious('FieldName', 'SelectField')
    expect(parentFieldNode).to.be.a(Node)
    expect(parentFieldNode.type).to.equal('FieldName')
    expect(parentFieldNode.value).to.equal('Parent')

    nullNode = parentFieldNode.findPrevious('FieldName', 'SelectField')
    expect(nullNode).to.be(null)

    ### (SELECT [Name] FROM Contacts) field ###
    node = leafs[11] # (SELECT [Name] FROM Contacts)
    expect(node).to.be.a(Node)
    expect(node.value).to.equal('Name')
    expect(node.type).to.equal('FieldName')

    selectClauseNode = node.findParent(selectTypeRegexp)
    expect(selectClauseNode).to.be.a(Node)
    expect(selectClauseNode.type).to.match(selectTypeRegexp)

    objectTypeNode = selectClauseNode.find('ObjectType')
    expect(objectTypeNode).to.be.a(Node)
    expect(objectTypeNode.type).to.equal('ObjectType')
    expect(objectTypeNode.value).to.equal('Contacts')

    selectClauseNode = selectClauseNode.findParent(selectTypeRegexp)
    expect(selectClauseNode).to.be.a(Node)
    expect(selectClauseNode.type).to.match(selectTypeRegexp)

    objectTypeNode = selectClauseNode.find('ObjectType')
    expect(objectTypeNode).to.be.a(Node)
    expect(objectTypeNode.type).to.equal('ObjectType')
    expect(objectTypeNode.value).to.equal('Account')

    ### WHERE Owner.[Name] LIKE 'A%' ###
    node = leafs[17] # (WHERE Owner.[Name] LIKE 'A%')
    expect(node).to.be.a(Node)
    expect(node.value).to.equal('Name')
    expect(node.type).to.equal('FieldName')

    ownerFieldNode = node.findPrevious('FieldName', 'SelectField')
    expect(ownerFieldNode).to.be.a(Node)
    expect(ownerFieldNode.type).to.equal('FieldName')
    expect(ownerFieldNode.value).to.equal('Owner')

    nullNode = ownerFieldNode.findPrevious('FieldName', 'SelectField')
    expect(nullNode).to.be(null)

    selectClauseNode = node.findParent(selectTypeRegexp)
    expect(selectClauseNode).to.be.a(Node)
    expect(selectClauseNode.type).to.match(selectTypeRegexp)

    objectTypeNode = selectClauseNode.find('ObjectType')
    expect(objectTypeNode).to.be.a(Node)
    expect(objectTypeNode.type).to.equal('ObjectType')
    expect(objectTypeNode.value).to.equal('Contacts')

    ### WHERE [NumOfEmployees] > 100 ###
    node = leafs[24] # (WHERE [NumOfEmployees] > 100)
    expect(node).to.be.a(Node)
    expect(node.value).to.equal('NumOfEmployees')
    expect(node.type).to.equal('FieldName')

    nullNode = node.findPrevious('FieldName', 'SelectField')
    expect(nullNode).to.be(null)

    selectClauseNode = node.findParent(selectTypeRegexp)
    expect(selectClauseNode).to.be.a(Node)
    expect(selectClauseNode.type).to.match(selectTypeRegexp)

    objectTypeNode = selectClauseNode.find('ObjectType')
    expect(objectTypeNode).to.be.a(Node)
    expect(objectTypeNode.type).to.equal('ObjectType')
    expect(objectTypeNode.value).to.equal('Account')

    ### ORDER BY [CreatedDate] DESC ###
    node = leafs[34] # ORDER BY [CreatedDate] DESC
    expect(node).to.be.a(Node)
    expect(node.value).to.equal('CreatedDate')
    expect(node.type).to.equal('FieldName')

    nullNode = node.findPrevious('FieldName', 'SelectField')
    expect(nullNode).to.be(null)

    selectClauseNode = node.findParent(selectTypeRegexp)
    expect(selectClauseNode).to.be.a(Node)
    expect(selectClauseNode.type).to.match(selectTypeRegexp)

    objectTypeNode = selectClauseNode.find('ObjectType')
    expect(objectTypeNode).to.be.a(Node)
    expect(objectTypeNode.type).to.equal('ObjectType')
    expect(objectTypeNode.value).to.equal('Account')

