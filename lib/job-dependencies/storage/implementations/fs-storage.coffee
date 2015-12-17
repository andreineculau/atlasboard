#-------------------------------
# Filesystem storage implementation
#-------------------------------
util = require('util')
fs = require('fs')
path = require('path')

StorageFS = (storageKey, options) ->
  @storageKey = storageKey
  @options = options or {}
  @storagePath = options.storagePath or path.join(process.cwd(), '/job-data-storage.json')
  return

util.inherits StorageFS, require('../storage-base')

StorageFS::get = (key, callback) ->
  self = this
  fs.readFile self.storagePath, (err, data) ->
    `var data`
    if err
      return callback(err)
    data = undefined
    try
      content = JSON.parse(data)
      data = if content[self.storageKey] then content[self.storageKey][key].data else null
    catch e
      return callback('Error reading JSON from file')
    callback null, data
    return
  return

StorageFS::set = (key, value, callback) ->
  self = this
  fs.readFile self.storagePath, (err, data) ->
    if err
      data = '{}'
    #new file
    content = {}
    try
      content = JSON.parse(data)
    catch e
      console.log 'error reading file ' + self.storagePath
    content[self.storageKey] = content[self.storageKey] or {}
    content[self.storageKey][key] = data: value
    fs.writeFile self.storagePath, JSON.stringify(content), (err, data) ->
      callback and callback(err, content)
      return
    return
  return

module.exports = StorageFS
