logger = require('tracer').colorConsole {
  format: '{{timestamp}} <{{title}}> {{message}}'
  dateformat: 'HH:MM:ss.L'
}

module.exports =
  logger: (job) ->
    prefix = ''
    prefix = "[#{job.dashboardName}] [#{job.name}] "  if job
    result = {}
    for level in ['info', 'warn', 'error']
      do (level) =>
        result[level] = (msg) =>
          msg = prefix + msg
          logger[level] msg
    # FIXME
    result.log = result.info
    result
