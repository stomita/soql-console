###
# parser_test.coffee
###
expect = require 'expect.js'

Node   = require '../build/node'
SoqlCompletion = require '../build/soql-completion'

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

