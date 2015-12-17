fs = require 'fs'
path = require 'path'
_ = require 'lodash'
async = require 'async'
helpers = require './helpers'
logger = require('./logger').logger()

module.exports =
  filters:
    dashboards: (dashboardJsonFilename) ->
      try
        dashboardJson = JSON.parse fs.readFileSync dashboardJsonFilename
        dashboardJson.enabled isnt false
      catch e
        logger.error "#{dashboardJsonFilename} has an invalid format or file doesn't exist"
        false

  resolveLocation: (name, type, extension) ->
    if type in ['widgets', 'jobs']
      # jobs/job1/job1.js
      path.join type, name, name + extension
    else
      # dashboards/dashboard.json
      path.join type, name + extension

  resolveCandidates: (items, name, type, extension = '') ->
    criteria = ''
    if name.indexOf('#') > -1
      pkgName = name.split('#', 2)[0]
      name = name.split('#', 2)[1]
      #package/jobs/job1/job1.js
      criteria = path.join pkgName, @resolveLocation name, type, extension
    else
      #jobs/job1/job1.js
      criteria = @resolveLocation(name, type, extension)
    criteria = path.sep + criteria
    items.filter (item) ->
      item.indexOf(criteria) > -1

  findItemsInPkgDir: (pkgDir, type, extension, cb) ->
    result = {
      dir: pkgDir
      items: []
    }
    typeDir = path.join pkgDir, type

    return cb null, result  unless fs.existsSync typeDir

    # this functions parses:
    # - packages/default/<type>/*
    # - packages/otherpackages/<type>/*
    # for dashboards, or:
    # - packages/default/<type>/*/*.js
    # - packages/otherpackages/<type>/*/*.js
    # for jobs and widgets
    fs.readdir typeDir, (err, items) =>
      return cb err  if err?

      items = _.compact _.map items, (item) ->
        itemFile = path.join typeDir, item
        if fs.statSync(itemFile).isDirectory()
          # /job/job1/job1.js
          itemFile = path.join itemFile, item + extension
        if path.extname(itemFile) is extension and fs.existsSync itemFile
          itemFile
        else
          undefined

      items = items.filter @filters[type]  if @filters[type]?
      result.items = items
      cb null, result

  getFirst: (wallboardDir, name, type, extension, cb) ->
    @get wallboardDir, type, extension, (err, items) =>
      return cb err  if err?
      candidates = @resolveCandidates(items, name, type, extension)
      return cb()  unless candidates.length
      cb null, candidates[0]

  get: (wallboardDir, type, extension, cb) ->
    @getByPkg wallboardDir, type, extension, (err, itemsByPkg) ->
      return cb err  if err?
      result = []
      for {items} in itemsByPkg
        result = result.concat items
      cb null, result

  getByPkg: (wallboardDir, type, extension, cb) ->
    helpers.findPkgDirs wallboardDir, (err, pkgDirs) =>
      return cb err  if err?
      async.map pkgDirs, (pkgDir, cb) =>
        @findItemsInPkgDir pkgDir, type, extension, cb
      , (err, items) ->
        cb null, items
