api_url = 'https://api.hipchat.com/'
qstring = require('querystring')

module.exports.create = (options) ->
  request = options.request or require('request')
  if !options.api_key
    throw 'api_key required'
  errors = 
    400: 'Bad request. Please check your data'
    401: 'Unauthorized: API KEY not valid'
    403: 'You have exceeded the rate limit'
    404: 'Not found'
    406: 'You requested an invalid content type'
    500: 'Server Error'
    503: 'The method you requested is currently unavailable (due to maintenance or high load'

  onResponseBuilder = (callback) ->
    (err, response, body) ->
      if callback
        err_msg = null
        if err or !response or response.statusCode != 200
          err_msg = err
          if response and errors[response.statusCode]
            err_msg += ' ' + errors[response.statusCode] + '; ' + body
        callback err_msg, if response then response.statusCode else null, body
      return

  {
    'message': (roomId, from, message, notify, callback) ->
      url = api_url + 'v1/rooms/message?format=json&auth_token=' + options.api_key
      data = 
        room_id: roomId
        from: from
        message: message
        notify: notify
      request.post {
        url: url
        headers: 'content-type': 'application/x-www-form-urlencoded'
        body: qstring.stringify(data)
      }, onResponseBuilder(callback)
      return
    'roomInfo': (roomId, callback) ->
      url = api_url + 'v2/room/' + roomId + '?format=json&auth_token=' + options.api_key
      request.get {
        url: url
        json: true
      }, onResponseBuilder(callback)
      return

  }
