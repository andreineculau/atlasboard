_ = require 'lodash'
domain = require 'domain'
jobManager = require './job-manager'

module.exports =
  domain: undefined

  initialize: () ->
    @domain = domain.create()
    @domain.on 'error', (error) ->
      console.error error.stack

  scheduleNext: (job, widgets) ->
    setTimeout =>
      @schedule job, widgets
    , job.config.interval

  handleError: (job, widgets, error, startTime) ->
    endTime = Date.now()
    executionTime = (endTime - startTime) / 1000
    job.dependencies.logger.error "Executed with errors: #{error}"
    # in case of error retry in one third of the original interval or 1 min, whatever is lower
    job.config.interval = Math.min job.config.originalInterval / 3, 60000
    # -------------------------------------------------------------
    # Decide if we hold error notification according to widget config.
    # if the retryOnErrorTimes property found in config, the error notification
    # won´t be sent until we reach that number of consecutive errrors.
    # This will prevent showing too many error when connection to flaky, unreliable
    # servers.
    # -------------------------------------------------------------
    #
    sendError = true
    if not job.firstRun
      if job.config.retryOnErrorTimes
        job.retryOnErrorCounter ?= 0
        if job.retryOnErrorCounter <= job.config.retryOnErrorTimes
          job.dependencies.logger.warn "Attempting #{job.retryOnErrorCounter} more times"
          sendError = false
          job.retryOnErrorCounter += 1
    else
      # this is the first run for this job so if it fails, we want to inform immediately
      # since it may be a configuration or dev related problem.
      job.firstRun = false
    return  unless sendError
    config = _.mapValues job.config, (value, key) ->
      return undefined  if key[0] is '_'
      value
    job.send {
      error
      _: {
        startTime
        endTime
        executionTime
        config
      }
    }

  schedule: (job, widgets) ->
    task = @domain.bind job.task

    job.config.interval ?= 60 * 1000
    job.config.interval = 1000  if job.config.interval < 1000
    job.config.originalInterval ?= job.config.interval

    try
      startTime = Date.now()
      cb = (err, data) =>
        if err?
          @handleError job, widgets, err, startTime
          return @scheduleNext job, widgets

        endTime = Date.now()
        executionTime = (endTime - startTime) / 1000

        job.retryOnErrorCounter = 0
        job.logger.log "Executed OK. Took #{executionTime}s"

        job.config.interval = job.config.originalInterval
        data ?= {}
        config = _.mapValues job.config, (value, key) ->
          return undefined  if key[0] is '_'
          value
        data._ = {
          startTime
          endTime
          executionTime
          config
        }
        job.send data
        @scheduleNext job, widgets

      args = [cb]
      if job.task.length > 1
        jobManager.fillDependencies job  if not job.dependencies?
        args = [job.config, job.dependencies, cb]

      task.apply job, args
    catch e
      job.logger.error "Uncaught exception executing job: #{e.toString()}"
      @handleError job, widgets, e, startTime
      @scheduleNext job, widgets
