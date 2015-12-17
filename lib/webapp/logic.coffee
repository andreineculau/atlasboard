fs = require 'fs'
path = require 'path'
_ = require 'lodash'
async = require 'async'
cssModule = require 'css'
stylus = require 'stylus'
nib = require 'nib'

helpers = require '../helpers'
logger = require('../logger').logger()
itemManager = require '../item-manager'

getSafeItemName = (item_name) ->
  path.basename(item_name).split('.')[0]

module.exports =
  list: ({wallboardDir, filters}, req, res) ->
    itemManager.get wallboardDir, 'dashboards', '.json', (err, dashboardJsonFilenames) ->
      if err
        logger.error err
        return res.status(400).send 'Error loading dashboards'

      if filters.dashboardFilter?
        dashboardJsonFilenames = _.filter dashboardJsonFilenames, (dashboardJsonFilename) ->
          dashboardName = path.basename dashboardJsonFilename, '.json'
          _.some filters.dashboardFilter, (filter) -> dashboardName.match filter

      if dashboardJsonFilenames.length is 1
        return res.redirect './' + getSafeItemName dashboardJsonFilenames[0]

      availableDashboards = dashboardJsonFilenames.map (file) ->
          path.basename file, '.json'

      res.render path.join(__dirname, 'tpl', 'dashboards.ejs'), dashboards: availableDashboards.sort()

  dashboard: ({wallboardDir}, dashboardName, req, res) ->
    dashboardName = getSafeItemName(dashboardName)
    itemManager.getFirst wallboardDir, dashboardName, 'dashboards', '.json', (err, dashboardPath) ->
      if err
        return res.status(400).send err
      if not dashboardPath?
        return res.status(404).send "Trying to render dashboard #{dashboardName}, but couldn't find any dashboard in the packages folder"

      try
        dashboardJson = JSON.parse(fs.readFileSync(dashboardPath))
        for widget, widgetIndex in dashboardJson.layout.widgets
          widget.component ?= widget.widget #FIXME
          widget.id = [
            widget.job
            path.basename(dashboardPath, '.json')
            widget.component
            widgetIndex
          ].join '_'
      catch e
        return res.status(400).send 'Invalid dashboard config file'
      res.render path.join(__dirname, 'tpl', 'dashboard.ejs'), {
        dashboardName
        dashboardJson
      }

  dashboardJs: ({wallboardDir}, wallboard_assets_folder, dashboardName, req, res) ->
    dashboardName = getSafeItemName(dashboardName)
    itemManager.getFirst wallboardDir, dashboardName, 'dashboards', '.json', (err, dashboardPath) ->
      if err
        return res.status(400).send err
      if not dashboardPath
        return res.status(404).send "Trying to render dashboard #{dashboardName}, but couldn't find any dashboard in the packages folder"
      try
        dashboardJson = JSON.parse(fs.readFileSync(dashboardPath))
        for widget, widgetIndex in dashboardJson.layout.widgets
          widget.component ?= widget.widget #FIXME
          widget.id = [
            widget.job
            path.basename(dashboardPath, '.json')
            widget.component
            widgetIndex
          ].join '_'
      catch e
        return res.status(400).send 'Error reading dashboard'
      if !dashboardJson.layout.customJS
        return res.status(200).send ''
      res.type 'application/javascript'
      assets = dashboardJson.layout.customJS.map((file) ->
        path.join wallboard_assets_folder, 'javascripts', file
      )
      assets.forEach (file) ->
        if fs.existsSync(file)
          res.write fs.readFileSync(file) + '\n\n'
        else
          logger.error "#{file} not found"
        return
      #TODO: minify, cache, gzip
      res.end()
      return
    return

  component: ({wallboardDir}, componentName, req, res) ->
    componentName = getSafeItemName componentName
    style = ''
    # FIXME widgets -> components
    async.series [
      (cb) =>
        itemManager.getFirst wallboardDir, componentName, 'widgets', '.styl', (err, stylFilename) =>
          return cb()  if err? or not stylFilename?
          stylus(fs.readFileSync(stylFilename, 'utf-8')).set('warn', false).use(nib()).render (err, css) =>
            return cb err  if err?
            css = @addNamespace css, componentName
            style += "<style>#{css}</style>"
            cb()
      (cb) =>
        itemManager.getFirst wallboardDir, componentName, 'widgets', '.css', (err, cssFilename) =>
          return cb()  if err? or not cssFilename?
          css = fs.readFileSync cssFilename
          css = @addNamespace css, componentName
          style += "<style>#{css}</style>"
          cb()
      (cb) ->
        itemManager.getFirst wallboardDir, componentName, 'widgets', '.html', (err, htmlFilename) ->
          if err? or not htmlFilename?
            res.status(400).send 'Error rendering widget\'s html and css'
            return cb()
          res.type 'text/html'
          res.write style
          res.write fs.readFileSync htmlFilename, 'utf-8'
          res.end()
          cb()
    ],

  componentJs: ({wallboardDir}, componentName, req, res) ->
    componentName = getSafeItemName(componentName)
    # FIXME widgets -> components
    itemManager.getFirst wallboardDir, componentName, 'widgets', '.js', (err, jsFilename) ->
      if err? or not jsFilename?
        return res.status(400).send 'Error rendering widget\'s javascript'
      res.sendFile jsFilename

  widgetResource: ({wallboardDir}, resource, req, res) ->
    return res.status(400).send 'resource id not specified'  unless resource?
    #sanitization
    input = resource.split('/')
    return res.status(400).send 'bad input'  unless input.length is 3
    packageName = input[0]
    widgetId = input[1]
    resourceName = input[2]
    #TODO: add extra sanitization
    resourcePath = path.join wallboardDir, packageName, 'widgets', widgetId, resourceName
    return res.status(404).send 'resource not found'  unless fs.existsSync resourcePath
    res.sendFile resourcePath

  namespaceRulesAST: (rules, widgetIdspace) ->
    rules.forEach (rule) ->
      if rule.selectors
        rule.selectors = rule.selectors.map((selector) ->
          if selector == '@font-face'
            return selector
          'li[data-widget-component="' + widgetIdspace + '"] ' + selector
        )
      # Handle rules within media queries
      if rule.rules
        namespaceRulesAST rule.rules

  addNamespace: (css, widgetIdspace) ->
    return  unless css?
    cssAST = cssModule.parse(css.toString())
    @namespaceRulesAST cssAST.stylesheet.rules, widgetIdspace
    cssModule.stringify(cssAST)
