###
# soql-completion_test.coffee
###
expect = require 'expect.js'

Node   = require '../build/node'
SoqlCompletion = require '../build/soql-completion'

###
###
describe "completing", ->
  ###
  ###
  before ->
    SoqlCompletion.connection = require './stub/connection'

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

