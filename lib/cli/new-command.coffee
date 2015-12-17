path = require 'path'
childProcess = require('child_process')
_ = require 'lodash'
helpers = require '../helpers'
scaffolding = require './scaffolding'

module.exports =
  descr: 'Creates a new fully functional dashboard with the name given in NAME
          whose base lies in the current directory.'

  example: 'atlasboard new NAME'

  run: (args, cb = _.noop) ->

    if args.length < 1
      return cb('Missing arguments')

    newDir = args[0]
    srcDir = path.join __dirname, '..', '..', 'samples', 'project'
    destDir = path.join process.cwd(), newDir

    @newProject srcDir, destDir, (err) ->
      return cb err  if err

      process.chdir newDir
      console.log 'Installing npm dependencies...'
      child = childProcess.spawn 'npm', ['install', '--production'], stdio: 'inherit'

      child.on 'error', ->
        console.log()
        console.log 'Error installing dependencies. Please run "npm install" inside the dashboard directory'
        cb 'Error installing dependencies'

      child.on 'exit', ->
        console.log()
        console.log 'SUCCESS !!'
        console.log()
        console.log "New project \"#{newDir}\" successfully created. Now:"
        console.log()
        console.log " 1. cd #{newDir}"
        console.log ' (optional: you can import the Atlassian package by running
                       `git init;
                        git submodule add https://bitbucket.org/atlassian/atlasboard-atlassian-package packages/atlassian`'
        console.log ' 2. start your server by running
                         `atlasboard start`'
        console.log ' 3. visit it at http://localhost:3000'
        console.log()
        cb()

  newProject: (srcDir, destDir, cb) ->
    name = path.basename destDir
    parentDir = path.dirname destDir

    if not name.match /^[a-zA-Z0-9_-]*$/
      return cb 'Invalid wallboard name'

    if not helpers.isPathContainedInRoot destDir, process.cwd()
      return cb 'Invalid directory'

    if directoryHasAtlasBoardProject parentDir
      return cb 'You can not create an atlasboard
                 inside a directory containing an atlasboard (at least we think you shouldn\'t)'

    if fs.existsSync destDir
      return cb "There is already a directory here called #{destDir}. Please choose a new name."

    console.log()
    console.log "Generating a new AtlasBoard project at #{destDir}..."

    options = {
      engine: 'ejs'
      data: {
        name
      }
    }

    scaffolding.scaffold srcDir, destDir, options, cb
