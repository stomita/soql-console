###
# config.coffee
###
module.exports =
  if location.hostname == 'localhost'
    clientId: '3MVG9rFJvQRVOvk5xdqA1E9sy80kQKBRYqRSeyFlifWv1D.oX8N0mzDWIg1Ld6X6pVVIVufI_2En2IG0fiNlb'
    redirectUri: 'http://localhost:5000/'
  else if location.hostname == 'soql-console.herokuapp.com'
    clientId: '3MVG9rFJvQRVOvk5xdqA1E9sy88d1CWjUyfV0g3RsIwNd2URhiJP9bn_uurByb3Zu77Bd0f8MVjdG2nz8kN.O'
    redirectUri: 'https://soql-console.herokuapp.com/'
  else
    clientId: ''
    redirectUri: ''
