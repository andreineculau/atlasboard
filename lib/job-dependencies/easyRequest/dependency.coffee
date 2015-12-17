###*

easyRequest

- Provides a layer of abstraction to easily query HTTP endpoints.
- It does all the error handling (bad response, authentication failed, bad json response, etc).
###

module.exports = (job, io, config) ->
  request = require('request')

  query_request = (options, callback) ->
    request options, (err, response, body) ->
      if err or !response or response.statusCode != 200
        error_msg = (err or (if response then 'bad statusCode: ' + response.statusCode else 'bad response')) + ' from ' + options.url
        callback error_msg
      else
        callback null, body
      return
    return

  {
    JSON: (options, callback) ->
      query_request options, (err, body) ->
        if err
          return callback(err)
        jsonBody = undefined
        try
          jsonBody = JSON.parse(body)
        catch e
          return callback('invalid json response')
        callback null, jsonBody
        return
      return
    HTML: (options, callback) ->
      query_request options, (err, body) ->
        if err
          return callback(err)
        callback null, body
        return
      return

  }
