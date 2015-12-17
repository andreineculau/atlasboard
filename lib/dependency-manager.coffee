fs = require 'fs'
path = require 'path'
_ = require 'lodash'
async = require 'async'
semver = require 'semver'
helpers = require './helpers'

atlasDir = path.join __dirname, '..'
# in both test and production env will be located here.

module.exports =
  checkAtlasEngine: (pkgDir, cb) ->
    async.parallel [
      (cb) ->
        helpers.readPkgJson pkgDir, cb
      (cb) ->
        helpers.readPkgJson atlasDir, cb
    ], (err, [pkgJson, atlasJson]) ->
      return cb err  if err?
      if pkgJson.engines and
         pkgJson.engines.atlasboard and
         not semver.satisfies atlasJson.version, pkgJson.engines.atlasboard
        return cb "Atlasboard version does not satisfy package dependencies at #{pkgDir}.
                   Please consider updating your version of atlasboard.
                   Version required: #{pkgJson.engines.atlasboard}.
                   Atlasboard version: #{atlasJson.version}"
      cb()

  install1: (pkgDir, cb) ->
    currPath = process.cwd()
    console.log "Checking npm dependencies for #{pkgDir}..."
    helpers.executeCommand 'npm', ['install', '--production', pkgDir], {cwd: pkgDir}, (err, code) ->
      if err
        return cb "Error installing dependencies for #{pkgDir}. ERROR: #{err}"
      else if code isnt 0
        return cb "Error installing #{pkgDir}"
      cb()

  install: ({wallboardDir}, cb) ->
    helpers.findPkgDirs wallboardDir, (err, pkgDirs) =>
      return cb err  if err?
      async.each pkgDirs, @checkAtlasEngine, (err) =>
        return cb err  if err?
        async.eachSeries pkgDirs, @install1, cb
