###
main.coffee
###

# dummy 
define "fs", {}
define "path", {}
define "file", {}
define "system", {}

if location.hostname != 'localhost' && location.protocol != 'https:'
  location.protocol = 'https:'

requirejs.config
  paths:
    async: "/lib/async/async"


require [ 
  './soql-autocompl'
  './stub/connection'
  './server-proxy/connection'
  './caret'
  './login'
  './result-table'
], (compl, stubConnection, proxyConnection, caret, login, resultTable) ->
  $ ->
    compl.connection = stubConnection
    listeners =
      login : -> compl.connection = proxyConnection
      logout : -> compl.connection = stubConnection
    login.init(proxyConnection, listeners)
    init(compl)

###
###
init = (compl) ->

  resultTable = require './result-table'

  ###
  ###
  completing = false
  pivot = -1


  ###
  ###
  startQuery = ->
    soql = $('#query textarea.input').val()
    startLoading()
    startTime = new Date().getTime()
    compl.connection.query soql,
      onSuccess: (res) ->
        stopLoading()
        elapsedTime = (new Date().getTime() - startTime)
        showMessage "Query executed successfully",
          "elapsed time : #{elapsedTime} msec, total size: #{res.totalSize}"
        window.$result = res # for debug
        html = resultTable.renderAsHTML(res)
        $('#result').html(html)
        $('#result > table').addClass('table table-hover table-bordered')
        $('#links').show()
        $('#links a').off 'click'
        $('#links a.csv-link').on 'click', (e) ->
          e.preventDefault()
          e.stopPropagation()
          csv = resultTable.renderAsCSV(res)
          location.href = "data:text/csv;charset=UTF-8,#{encodeURIComponent(csv)}"
        $('#links a.tsv-link').on 'click', (e) ->
          e.preventDefault()
          e.stopPropagation()
          tsv = resultTable.renderAsTSV(res)
          location.href = "data:text/tsv;charset=UTF-8,#{encodeURIComponent(tsv)}"
      onFailure: (err) ->
        stopLoading()
        showMessage err.errorCode, err.message, 'error'

  startLoading = ->
    $('#alert, #result').empty()
    $('#links').hide()
    $('#console').find('button, textarea').attr('disabled', 'disabled').addClass('disabled')

  stopLoading = ->
    $('#console').find('button, textarea').removeAttr('disabled').removeClass('disabled')

  ###
  ###
  showMessage = (title, message, type='success') ->
    msg = $("<div class=\"alert alert-#{type} fade in\" />")
      .append($('<button class="close" data-dismiss="alert">&times;</button>'))
      .append($('<strong>').text(title || ''))
      .append($('<p>').text(message || ''))
    $('#alert').empty().append(msg)

  clearMessage = () ->
    $('#alert').empty()

  ###
  ###
  $('#query button.query').click -> startQuery()
  compl.autocomplete($('#query textarea.input'), startQuery)
  $('#query textarea.input').focus()

