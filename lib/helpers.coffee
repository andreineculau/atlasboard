fs = require 'fs'
path = require 'path'
childProcess = require 'child_process'
readJson = require 'read-package-json'

module.exports =
  directoryHasAtlasBoardProject: (dir = '.') ->
    items = [
      'packages'
      'package.json'
      'config'
    ]
    #the proyect should have these items
    for item in items
      fs.existsSync path.join dir, item

  isPathContainedInRoot: (pathDir, root) ->
    if typeof root != 'string' or typeof pathDir != 'string'
      return false
    if pathDir[0] != '/'
      pathDir = path.join(process.cwd(), pathDir)
    pathDir.indexOf(root) == 0

  areValidPathElements: (paths) ->
    valid = (path) ->
      return false  unless path?
      malicious = false
      path = path.toString()
      #in case it is another type, like number
      if path.indexOf('/') != -1 or path.indexOf('\\') != -1
        malicious = true
      if path.indexOf('..') != -1
        malicious = true
      if path.indexOf('\u0000') != -1
        malicious = true
      if malicious
        console.log 'Malicious path detected: %s', path
        false
      else
        true

    paths = [paths]  unless _.isArray paths
    _.every paths, valid

  executeCommand: (cmd, args, options = {}, cb) ->
    options.stdio = 'inherit'
    child = childProcess.spawn cmd, args, options
    child.on 'error', cb
    child.on 'exit', (code) ->
      cb null, code

  readPkgJson: (pkgDir, cb) ->
    pkgJsonFilename = path.join pkgDir, 'package.json'
    readJson pkgJsonFilename, cb

  findPkgDirs: (dashboardDir, cb) ->
    packagesDir = path.join dashboardDir, 'packages'
    fs.readdir packagesDir, (err, pkgs) ->
      return cb err  if err?
      # convert to absolute path
      pkgDirs = pkgs.map (pkg) ->
        path.join packagesDir, pkg
      # make sure we have package.json file
      pkgDirs = pkgDirs.filter (pkgDir) ->
        fs.statSync(pkgDir).isDirectory() and fs.existsSync path.join pkgDir, 'package.json'
      cb null, pkgDirs
