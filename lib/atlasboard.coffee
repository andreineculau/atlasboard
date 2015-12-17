fs = require 'fs'
path = require 'path'
http = require 'http'
_ = require 'lodash'
async = require 'async'

helpers = require './helpers'

jobManager = require './job-manager'
dependencyManager = require './dependency-manager'
scheduler = require './scheduler'

eventQueue = require './event-queue'
logger = require('./logger').logger()

startJob = (job) ->
  job.send = (data) ->
    eventQueue.send @id, data

  if job.widget.disabled?
    return job.send {
      error: 'disabled'
    }

  return  unless job.task?

  _.defer () ->
    scheduler.schedule job

module.exports = (options = {}, cb) ->
  http.globalAgent.maxSockets = Infinity

  io = undefined

  async.waterfall [
    (cb) ->
      return cb()  if options.quick?
      dependencyManager.install options, cb
    (cb) ->
      require('./webapp/app') options, (app) ->
        console.log()
        console.log "AtlasBoard server started. Go to: http://localhost:#{options.port} to access your dashboard."
        console.log()

        io = app.io
        eventQueue.initialize io
        cb()
    (cb) ->
      scheduler.initialize()
      jobManager.getWallboardJobs options, cb
    ({jobs, jobModulesPerDashboard}, cb) ->
      if not jobs.length
        logger.warn 'No jobs found matching the current configuration and filters.'
        output = []
        for dashboardName, jobModules of jobModulesPerDashboard
          output.push dashboardName
          for jobModule in jobModules
            output.push "  #{jobModule}"
        logger.info "Available dashboards and jobs:\n" + output.join '\n'
        return cb()

      async.each jobs, (job) ->
        job.io = io
        job.logger = require('./logger').logger job
        startJob job
      , cb
  ], cb
