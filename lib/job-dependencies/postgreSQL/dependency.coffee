pg = require('pg')

query = (connectionString, query, params, callback) ->
  # handle case where params are omitted
  if arguments.length == 3
    callback = params
    params = []
  pg.connect connectionString, (err, client, done) ->
    if err
      console.error 'Error connecting to postgreSQL:' + err
      done()
      return callback(err)
    client.query query, params, (err, results) ->
      if err
        console.error 'Error executing postgreSQL query:' + err
        done()
        return callback(err)
      done()
      callback null, results
      return
    return
  return

module.exports = (job, io, config) ->
  {
    pg: pg
    query: query
  }
