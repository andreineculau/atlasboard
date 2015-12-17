#!/usr/bin/env coffee

fs = require 'fs'
path = require 'path'
commands = {
  generate: require './generate-command'
  new: require './new-command'
  list: require './list-command'
  start: require './start-command'
}
logger = require('../logger').logger()

args = process.argv
commandName = args[2]
commandArgs = args.slice 3

runCommand = (name, args) ->
  commands[name].run args, (err) ->
    return  unless err?
    logger.error err
    process.exit 1

showHelp = ->
  packageJson = JSON.parse(fs.readFileSync(path.join(__dirname, '..', '..', 'package.json')))
  console.log()
  console.log "AtlasBoard Version #{packageJson.version}"
  console.log()
  console.log 'usage: atlasboard [command] [options]\n'
  console.log 'LIST OF AVAILABLE COMMANDS:\n'

  for commandName, command of commands
    console.log "#{commandName}:"
    console.log '  ', command.descr.replace /\n/g, '\n  '
    console.log '  ', 'ex: ', command.example.replace /\n/g, '\n       '
    console.log()

if commands[commandName]
  runCommand commandName, commandArgs
else
  showHelp()
