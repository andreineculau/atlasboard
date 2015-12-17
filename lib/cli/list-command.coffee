path = require 'path'
_ = require 'lodash'
async = require 'async'
itemManager = require '../item-manager'

module.exports =
  descr: 'List all available components (widgets or jobs) within all available packages'

  example: 'atlasboard list'

  run: (args, cb = _.noop) ->
    localPkgsDir = path.join process.cwd(), 'packages'
    atlasPkgsDir = path.join __dirname, '..', '..', 'packages'

    parsePkg = (pkg) ->
      console.log "\u0009\u0009Package \"#{path.basename(pkg.dir)}\""
      for item in pkg.items
        console.log "\u0009\u0009    - #{path.basename(item, '.js')}"

    @list [localPkgsDir, atlasPkgsDir], cb

  list: (paths, cb) ->
    @parse paths, (err, pkgs) ->
      return cb 'Error reading package folder'  if err

      console.log 'Available widgets and jobs within all package folders:'

      for pkg in packages
        console.log " #{pkg.package}"
        console.log '\u0009- Widgets:'
        parseItem widget  for widget in pkg.widgets
        console.log '\u0009- Jobs:'
        parseItem job  for job in pkg.jobs
      cb()

  parse: (paths, cb) ->
    paths = _.unique paths

    async.map paths, parse1, (err, lists) ->
      # remove null items if any
      cb err, _.compact lists

  parse1: (path, cb) ->
    list = {
      package: path
    }
    itemManager.getByPackage path, 'widgets', '.js', (err, widgets) ->
      return cb err  if err
      list.widgets = widgets
      itemManager.getByPackage path, 'jobs', '.js', (err, jobs) ->
        return cb err  if err
        list.jobs = jobs
        list = null  unless list.widgets.length and list.jobs.length
        cb null, list
