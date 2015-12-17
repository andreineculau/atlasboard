fs = require 'fs'
path = require 'path'
ejs = require 'ejs'
mkdirp = require 'mkdirp'

module.exports =
  _applyReplacements: (fileName, replacements) ->
    for from, to of replacements
      if fileName.indexOf(from) > -1
        fileName = fileName.replace from, to
        break
    fileName

  _copyRecursiveSync: (src, dest) ->
    exists = fs.existsSync src
    stats = exists and fs.statSync src
    isDirectory = exists and stats.isDirectory()
    if exists and isDirectory
      fs.mkdirSync dest
      for item in fs.readdirSync src
        @_copyRecursiveSync path.join(src, item), path.join(dest, item)
    else
      destinationFile = applyReplacements(dest, options.replace or {})
      if options.engine is 'ejs'
        fs.writeFileSync destinationFile, ejs.render(fs.readFileSync(src).toString(), options.data)
      else
        fs.linkSync src, destinationFile

  scaffold: (templateSourceDir, destinationDir, options, cb) ->
    if not cb?
      # options parameter is optional
      cb = options
      options = {}
    mkdirp path.dirname(destinationDir), (err) =>
      return cb(err)  if err
      @_copyRecursiveSync templateSourceDir, destinationDir
      cb()
