fs = require 'fs'
path = require 'path'
http = require 'http'

express = require 'express'
bodyParser = require 'body-parser'
serveStatic = require 'serve-static'
errorHandler = require 'errorhandler'
stylus = require 'stylus'
nib = require 'nib'
socketio = require 'socket.io'

helpers = require '../helpers'
logger = require('../logger').logger()
logic = require './logic'

module.exports = (options, cb) ->
  {port, wallboardDir} = options
  atlasboardAssetsDir = path.join __dirname, '..', '..', 'assets'
  wallboardAssetsDir = path.join wallboardDir, 'assets'
  compiledAssetsDir = path.join wallboardAssetsDir, 'compiled'

  app = express()
  server = http.createServer app
  app.io = io = socketio.listen server
  io.on 'connection', (socket) ->
    socket.emit 'serverinfo', {
      startTime: (new Date()).getTime()
    }

  app.use bodyParser.urlencoded extended: true
  app.use bodyParser.json()
  app.use errorHandler()
  app.use (req, res, next) ->
    res.header 'Cache-Control', 'private, no-cache, no-store, must-revalidate'
    res.header 'Expires', '-1'
    res.header 'Pragma', 'no-cache'
    next()

  app.use stylus.middleware(
    src: atlasboardAssetsDir
    dest: compiledAssetsDir
    compile: (str, path) ->
      # optional, but recommended
      stylus(str).set('filename', path).set('warn', false).use nib()
  )

  app.use serveStatic wallboardAssetsDir
  app.use serveStatic compiledAssetsDir
  app.use serveStatic atlasboardAssetsDir

  app.get '/', (req, res) ->
    logic.list options, req, res

  app.get '/:dashboard', (req, res) ->
    logic.dashboard options, req.params.dashboard, req, res

  app.get '/:dashboard/js', (req, res) ->
    logic.dashboardJs options, wallboardAssetsDir, req.params.dashboard, req, res

  app.get '/components/:component', (req, res) ->
    logic.component options, req.params.component, req, res

  app.get '/components/:component/js', (req, res) ->
    logic.componentJs options, req.params.component, req, res

  app.get '/components/resources', (req, res) ->
    logic.componentResource options, req.query.resource, req, res

  server.on 'error', (e) ->
    logger.error "HTTP server error: #{e.toString()}"
    process.exit 1

  server.listen port, () ->
    cb app
