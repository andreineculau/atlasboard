# This dependency is experimental and not suitable for general consumption. The API available here is liable to change
# without notice.

module.exports = (job, io, config) ->

  addAuthConfig = (auth, opts) ->
    authData = job.config.globalAuth[auth]
    if authData and authData.username and authData.password
      opts.auth =
        user: authData.username
        pass: authData.password
    return

  {
    getPageById: (baseUrl, auth, pageId, cb) ->
      opts =
        url: baseUrl + '/rest/api/content/' + pageId
        qs: expand: 'body.view'
      addAuthConfig auth, opts
      job.dependencies.easyRequest.JSON opts, (err, body) ->
        if err
          return cb(err)
        cb null,
          title: body.title
          content: body.body.view.value
        return
      return
    getPageByCQL: (baseUrl, auth, query, cb) ->
      opts =
        url: baseUrl + '/rest/experimental/content'
        qs:
          expand: 'body.view'
          limit: 1
          cql: query
      addAuthConfig auth, opts
      job.dependencies.easyRequest.JSON opts, (err, body) ->
        if err
          return cb(err)
        if body.results.length == 0
          return cb(null, new Error('No page matching query ' + query))
        result = body.results[0]
        cb null,
          title: result.title
          content: result.body.view.value
          webLink: result._links.webui
        return
      return

  }
