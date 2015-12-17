
(function() {
  var options = {
        'reconnect': true,
        'reconnection delay': 1000,
        'reopen delay': 3000,
        'max reconnection attempts': Infinity,
        'reconnection limit': 60000,
        'path': window.location.pathname.replace(/[^\/]+$/, 'socket.io')
      };

  atlas.sockets.server = io.connect('/', options);
  atlas.sockets.widgets = io.connect('/widgets', options);

  atlas.sockets.server.on('connect', function() {
    $('#main').removeClass('offline');
    console.log('connected');
  });

  atlas.sockets.server.on('disconnect', function() {
    $('#main').addClass('offline');
    console.log('disconnected');
  });

  atlas.sockets.server.on('reconnecting', function () {
    console.log('reconnecting...');
  });

  atlas.sockets.server.on('reconnect_failed', function () {
    console.log('reconnected FAILED');
  });

  atlas.sockets.server.on('serverinfo', function(serverInfo) {
    if (!atlas.serverInfo) {
      return atlas.server = serverInfo;
    }
    if (serverInfo.startTime > atlas.server.startTime) {
      window.location.reload();
    }
  });

  atlas.sockets.widgets.on('connect', function() {
    $('> li', atlas.$gridster).each(function(index, widget) {
      var $widget = $(widget);
      atlas.bindWidget($widget, atlas.sockets.widgets);
    });
  });
})();
