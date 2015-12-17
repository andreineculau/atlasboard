fs = require 'fs'
path = require 'path'
_ = require 'lodash'
async = require 'async'

logger = require('./logger').logger()
itemManager = require './item-manager'

module.exports =
  getDashboardJobs: (allJobs, filename, json, filters) ->
    jobs = []
    for widget, widgetIndex in json.layout.widgets
      # widgets can run without a job, displaying just static html.
      continue  unless widget.job
      continue  if filters.jobFilter? and not _.some filters.jobFilter, (filter) -> widget.job.match filter

      candidateJobs = itemManager.resolveCandidates allJobs, widget.job, 'jobs'
      if not candidateJobs.length
        throw new Error "Error resolving job for #{widget.job} in #{filename}\n
                         Did you pull all the packages' dependencies? (they are git submodules)\n
                         $ git submodule init\n
                         $ git submodule update"
      widget.component ?= widget.widget # FIXME
      job = {
        name: widget.job
        dashboardName: path.basename filename, '.json'
        componentName: widget.component
        widget: widget
        config: widget.config
        task: require candidateJobs[0]
      }
      job.id = [
        job.name
        job.dashboardName
        job.componentName
        widgetIndex
      ].join '_'
      jobs.push job
    jobs

  getWallboardJobs: (options, cb) ->
    {wallboardDir, filters} = options
    configDir = path.join wallboardDir, 'config'

    filters ?= {}
    jobs = []
    commonDashboardJsonFilename = path.join configDir, 'dashboard_common.json'
    commonDashboardJson = {}

    if fs.existsSync(commonDashboardJsonFilename)
      try
        commonDashboardJson = JSON.parse fs.readFileSync commonDashboardJsonFilename
        commonDashboardJson.config ?= {}
      catch e
        return cb "Error reading #{commonDashboardJsonFilename} ..."

    itemManager.get wallboardDir, 'dashboards', '.json', (err, dashboardJsonFilenames) =>
      return cb err  if err?

      async.parallel [
        (cb) ->
          itemManager.get wallboardDir, 'jobs', '.js', cb
        (cb) ->
          itemManager.get wallboardDir, 'jobs', '.coffee', cb
      ], (err, jobModules) =>
        return cb err  if err?

        jobModules = _.flatten jobModules
        jobModulesPerDashboard = {}
        for dashboardJsonFilename in dashboardJsonFilenames
          dashboardName = path.basename dashboardJsonFilename, '.json'
          jobModulesPerDashboard[dashboardName] = _.compact _.map jobModules, (jobModule) ->
            if _.startsWith jobModule, path.join dashboardJsonFilename, '..', '..'
              path.basename jobModule, path.extname jobModule
            else
              undefined
          continue  if filters.dashboardFilter? and not _.some filters.dashboardFilter, (filter) ->
            dashboardName.match filter
          try
            dashboardConfig = JSON.parse fs.readFileSync dashboardJsonFilename
            dashboardJobs = @getDashboardJobs jobModules, dashboardJsonFilename, dashboardConfig, filters
          catch e
            return cb e
          jobs = jobs.concat dashboardJobs
        cb null, {jobs, jobModulesPerDashboard}

  fillDependencies: (job) ->
    job.dependencies = {}
    depsDir = path.join __dirname, 'job-dependencies'
    deps = fs.readdirSync depsDir
    for dep in deps
      depDir = path.join depsDir, dep
      continue  unless fs.statSync(depDir).isDirectory()
      try
        main = path.join depDir, 'dependency'
        job.dependencies[dep] = require(main)(job, job.io, job.config) # FIXME
      catch e
        console.error "Error resolving dependency #{dep}. ERROR: #{e.toString()}"
        throw new Error 'error loading dependencies'
    job.logger = job.dependencies.logger
