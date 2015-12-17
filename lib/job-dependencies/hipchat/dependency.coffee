module.exports = (job, io, config) ->
  if job.config.token
    #TODO: hipchat initialization should happen just once
    require('./hipchat').create api_key: job.config.token
  else
    null
