module.exports =
  io: undefined
  queue: {}

  initialize: (@io) ->
    @io.of('/widgets').on 'connection', (socket) =>
      socket.on 'resend', (data) =>
        return  unless @queue[data]?
        socket.emit data, @queue[data]

    # broadcast every log received
    @io.of('/log').on 'connection', (socket) ->
      socket.on 'log', (data) ->
        socket.broadcast.emit 'client', data

  send: (id, data) ->
    @queue[id] = data
    # emit to widget
    @io.of('/widgets').emit id, data
    # emit to logger
    @io.of('/log').emit 'client', {
      widgetId: id
      data: data
    }
