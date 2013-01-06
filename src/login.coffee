###
# login.coffee
###

config = require "./config"
storage = require "./storage"

loginDialog = null
connection = null
listeners = {}

###
###
init = (conn, lstnrs) ->
  connection = conn
  listeners = lstnrs || {}

  loginDialog = $('#login-dialog')

  loginDialog.find('select[name=env]').change ->
    if this.value == '_others_'
      loginDialog.find('input[name=server]').parents('.control-group').show()
    else
      loginDialog.find('input[name=server]').parents('.control-group').hide()

  loginDialog.find('button.connect').click -> authorize()

  $('#login-menu').click(-> connect(true) ).show()
  $('#logout-menu').click(logout).hide()

  connect()

###
###
connect = (force) ->
  accessToken = storage.get('accessToken')
  instanceUrl = storage.get('instanceUrl')
  id = storage.get('id')

  setLoginMenu(false)

  if accessToken && instanceUrl && id
    connection.initialize
      accessToken: accessToken
      instanceUrl: instanceUrl
      id: id
    connection.getUserInfo (err, userInfo) ->
      if err
        loginDialog.modal('show') if force
      else
        setLoginMenu(true)
        handleLogin(userInfo)
        connection.describeGlobal ->
  else
    loginDialog.modal('show') if force

###
###
handleLogin = (userInfo) ->
  $('#user-info-username').text(userInfo.username || userInfo.userName)
  listeners.login(userInfo) if listeners.login

handleLogout = (userInfo) ->
  listeners.logout if listeners.logout

###
###
setLoginMenu = (loggedIn) ->
  if loggedIn
    $('#login-menu').hide()
    $('#logout-menu').show()
  else
    $('#login-menu').show()
    $('#logout-menu').hide()

###
###
authorize = ->
  server = loginDialog.find('select[name=env]').val()
  server = loginDialog.find('input[name=server]').val() if server == "_others_"
  authzUrl = "https://#{server}/services/oauth2/authorize"
  authzUrl += "?response_type=token"
  authzUrl += "&client_id=#{config.clientId}"
  authzUrl += "&redirect_uri=#{encodeURIComponent(config.redirectUri)}"
  state = Math.random().toString(16).substring(2)
  authzUrl += "&state=#{state}"
  authzUrl += "&display=popup"
  w = window.open(authzUrl, null, 'width=800,height=600')
  PID = setInterval ->
    if w.closed
      clearInterval(PID)
      PID = null
      return
    try
      hash = w.location.href.split('#')[1]
      if hash
        params = parseQueryString(hash)
        storage.set('accessToken', params.access_token)
        storage.set('instanceUrl', params.instance_url)
        storage.set('id', params.id)
        clearInterval(PID)
        PID = null
        w.close()
        loginDialog.modal('hide')
        connect()
    catch e

  , 100


###
###
parseQueryString = (qstr) ->
  params = {}
  for pair in qstr.split('&')
    pair = pair.split('=')
    params[pair[0]] = decodeURIComponent(pair[1])
  params

###
###
logout = ->
  if confirm "Are you sure you want to logout ?"
    storage.remove('accessToken')
    storage.remove('instanceUrl')
    connect()


###
###
module.exports =
  init: init
