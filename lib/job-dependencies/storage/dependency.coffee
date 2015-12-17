module.exports = (job, io, config) ->
  fsStorageClass = require('./implementations/fs-storage')
  new fsStorageClass(job.id, {})
