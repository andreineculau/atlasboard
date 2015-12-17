path = require 'path'
_ = require 'lodash'
helpers = require '../helpers'
scaffolding = require './scaffolding'

module.exports =
  descr: 'Generates a basic widget/dashboard/job with the given NAME
          when run in an AtlasBoard project base directory.'

  example: 'atlasboard generate (widget/dashboard/job) NAME\n
            atlasboard generate (widget/dashboard/job) PACKAGE#NAME'

  run: (args, cb = _.noop) ->
    pkg = 'default'
    projectDir = process.cwd()

    if args.length < 2
      return cb 'Missing arguments'

    type = args[0]
    name = args[1]

    if name.indexOf('#') > -1
      pkgName = name.split('#', 2)[0]
      name = name.split('#', 2)[1]

    if !helpers.areValidPathElements([type, name])
      return cb 'Invalid input'

    if ['widget', 'dashboard', 'job'].indexOf(type) is -1
      return cb "Invalid generator #{type}.\n
                 Use one of: widget, dashboard, job."

    if !directoryHasAtlasBoardProject projectDir
      return cb 'It seems that no project exists here yet.\n
                 Please navigate to your project\'s root directory,
                 or generate one first.'

    if !name
      return cb "No #{type} name provided.\n
                 Please try again with a name after the generate parameter."

    @generate projectDir, pkgName, type, name, cb

  generate: (projectDir, pkgName, type, name, cb) ->
    templateFolder = path.join __dirname, '..', '..', 'samples'
    destPkgDir = path.join projectDir, 'packages', pkgName
    options = {}

    if type is 'dashboard'
      src = path.join templateFolder, 'dashboard', 'default.json'
      target = path.join destPkgDir, 'dashboards', name + '.json'
    else
      src = path.join templateFolder, type
      target = path.join destPkgDir, type + 's', name
      options = {
        engine: 'ejs'
        data: {
          name
        }
        replace:
          'widget.': "#{name}."
          'default.js': "#{name}.js"
      }

    if fs.existsSync target
      return cb "This #{type} already seems to exist at #{target}"

    console.log "Creating new #{type} at #{target}..."
    scaffolding.scaffold src, target, options, cb
