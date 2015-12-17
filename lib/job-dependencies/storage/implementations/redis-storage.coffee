#-------------------------------
# Filesystem storage implementation
# TODO
#-------------------------------
util = require('util')
fs = require('fs')
path = require('path')

StorageRedis = (options) ->
  @options = options or {}
  return

util.inherits StorageRedis, require('../storage-base')

StorageRedis::get = (key, callback) ->
  throw 'not implemented'
  return

StorageRedis::set = (key, value, callback) ->
  throw 'not implemented'
  return

module.exports = StorageRedis
