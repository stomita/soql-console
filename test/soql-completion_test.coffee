###
# soql-completion_test.coffee
###
expect = require 'expect.js'

Node   = require '../src/node'
SoqlCompletion = require '../src/soql-completion'

###
###
describe "completing", ->
  ###
  ###
  before ->
    SoqlCompletion.connection = require '../src/stub/connection'

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
        expect(candidate).to.have.property('type')
        expect(candidate.type in [ 'field', 'function' ]).to.be.ok()
        expect(candidate).to.have.property('fieldType') if candidate.type == 'field'
      expect(index).to.equal(@caret-2) # SELECT Id, |Na FROM Account
  ,
    input: "SELECT Id, Owner.| FROM Account"
    expect: (candidates, index) ->
      expect(candidates.length).to.be.above(0)
      for candidate in candidates
        expect(candidate).to.have.property('type', 'field')
        expect(candidate).to.have.property('fieldType')
      expect(index).to.equal(@caret)
  ,
    input: "SELECT Id, Name, (SELECT  FROM |) FROM Account"
    expect: (candidates, index) ->
      expect(candidates.length).to.be.above(0)
      for candidate in candidates
        expect(candidate).to.have.property('type', 'childRelationship')
      expect(index).to.equal(@caret)
  ,
    input: "SELECT Id, Max(Num|) mx FROM Account"
    expect: (candidates, index) ->
      expect(candidates.length).to.be.above(0)
      for candidate in candidates
        expect(candidate).to.have.property('type', 'field')
      expect(index).to.equal(@caret-3) # SELECT Id, Max(|Num)
  ]

  for cs in cases
    do (cs) ->
      describe "#{cs.desc ? 'input'} (#{cs.input})", ->

        it "should complete expected candidates", (done) ->
          cs.caret = cs.input.indexOf('|')
          cs.soql = cs.input.replace('|', '')
          SoqlCompletion.complete cs.soql, cs.caret, (candidates, index) ->
            expect(candidates).to.be.an('array')
            cs.expect(candidates, index)
            done()

