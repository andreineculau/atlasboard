path = require 'path'
_ = require 'lodash'
minimist = require 'minimist'
helpers = require '../helpers'
logger = require('../logger').logger()
atlasboard = require '../atlasboard'

module.exports =
  descr: 'When run in a project\'s base directory, starts the AtlasBoard server.\n
          Use $ atlasboard start <port> (to specify a port).\n
          Use --jobFilter or --dashboardFilter to only execute specific jobs or dashboards matching that regex'

  example: 'atlasboard start --port 3333              #runs atlasboard in port 3333\n
            atlasboard start --quick                  #don\'t bother installing packages\' node modules\n
            atlasboard start --job myjob              #runs only executing jobs matching \'myjob\'\n
            atlasboard start --dashboard \\bdash      #only loads dashboards matching \\bdash regex'

  run: (args, cb = _.noop) ->
    projectDir = process.cwd()

    options =  {
      filters: {}
      wallboardDir: process.cwd()
    }

    args = minimist args

    port = args.port
    port = 3000  if isNaN port
    options.port = port

    if args.quick?
      options.quick = true

    if args.job
      logger.log "Loading jobs matching #{args.job} only"
      args.job = [args.job]  unless _.isArray args.job
      options.filters.jobFilter = args.job

    if args.dashboard
      logger.log "Loading dashboards matching #{args.dashboard} only"
      args.dashboard = [args.dashboard]  unless _.isArray args.dashboard
      options.filters.dashboardFilter = args.dashboard

    @start projectDir, options, cb

  start: (projectDir, options, cb) ->
    if not helpers.directoryHasAtlasBoardProject()
      return cb 'I couldn\'t find a valid AtlasBoard dashboard.
                 Try generating one with `atlasboard new DASHBOARDNAME`.'
    atlasboard options, cb
