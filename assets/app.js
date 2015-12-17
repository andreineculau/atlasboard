//= jquery
//= console-helper
//= jquery.gridster.with-extras
//= underscore

atlas = atlas || {};

_.assign(atlas, {
  el: {},
  sockets: {},

  widgetJsDefaults: { // they can be overwritten by widget's custom implementation
    onInit: function (el) {
      var $el = $(el);
      $el.parent().children().hide();
      $el.parent().children('.loading-wrapper').show();
      /*
      var RATIO = 0.035; // ratio width vs font-size. i.e: for a 400 width widget, 400 * 0.035 = 14px font size as baseline
      var divWidth = $el.width();
      var newFontSize = divWidth * RATIO;
      $('.content.auto-font-resize', $el).css({'font-size': newFontSize + 'px'});
      */
    },

    onError: function (el, data) {
      console.error(data);
    },

    log: function (data) {
      atlas.sockets.log.emit('log', {widgetId: this.id, data: data}); // emit to logger
    }
  },

  onPreError: function(el, data) {
    var $el = $(el);
    $el.children().hide();
    $el.children('.gs-resize-handle').show();
    $el.addClass('error');
    $el.children('.error-wrapper').show().children('.content').html(data.error || '');
  },

  onPreData: function(el, data) {
    var $el = $(el);
    $el.children().hide();
    $el.children('.gs-resize-handle').show();
    $el.removeClass('error');
    $el.children('.success-wrapper').show();
  },

  logError: function(widget, err) {
    var errMsg = 'ERROR on ' + widget.id + ': ' + err;
    console.error(errMsg);
  },

  checkElapsed: function($widget, config) {
    var elapsed,
        maxElapsed,
        lastUpdate = $widget.attr('last-update');

    if (lastUpdate) {

      if (!config.interval) return;
      elapsed = new Date().getTime() - lastUpdate;
      maxElapsed = config.interval * (config.retryOnErrorTimes || 2);

      if ($('.widget-title span.widget-elapsed', $widget).length === 0) {
        $('.widget-title', $widget).append('<span class="widget-elapsed"></span>');
      }

      if (elapsed > maxElapsed) { // this widget if offline
        lastUpdate = ' <span class="alert alert_high">' + (new Date()).toTimeString() + '</span>';
        $('.widget-title span.widget-elapsed', $widget).html(str_elapsed);
        $widget.addClass('offline');
      } else {
        $('.widget-title span.widget-elapsed', $widget).html('');
        $widget.removeClass('offline');
      }
    }
  },

  bindWidget: function($widget, io) {
    var widgetComponent = $widget.attr('data-widget-component');
    var widgetId = $widget.attr('data-widget-id');

    var $loading = $('div.loading-wrapper', $widget)

    if ($loading.length) {
    } else {
	$loading = $('<div class="loading-wrapper"><div class="content"></div></div>').appendTo($widget).hide();
	var spinner = new Spinner({className: 'spinner', color:'#fff', width:5, length:15, radius: 25, lines: 12,  speed:0.7}).spin();
	$('.content', $loading).append(spinner.el);
    }

    var $error = $('div.error-wrapper', $widget)
    $error = $error.length ? $error : $('<div class="error-wrapper"><div class="content"></div>').appendTo($widget).hide();

    var $success = $('div.success-wrapper', $widget)
    $success = $success.length ? $success : $('<div class="success-wrapper"></div>').appendTo($widget).hide();

    // fetch component html and css
    $success.load('./components/' + widgetComponent, function() {

      // fetch widget js
      $.get('./components/' + widgetComponent + '/js', function(js) {

        var widgetJs;
        try{
          eval('widgetJs = ' + js);
          widgetJs.id = widgetId;
          widgetJs = $.extend({}, atlas.widgetJsDefaults, widgetJs);
          widgetJs.onInit($success[0]);
        }
        catch (e) {
          atlas.logError(widgetJs, e);
        }

        io.on(widgetId, function (data) { //bind socket.io event listener
          if (data.error) {
            atlas.onPreError.apply(widgetJs, [$widget, data]);
          } else {
            atlas.onPreData.apply(widgetJs, [$widget]);
          }

          var f = data.error ? widgetJs.onError: widgetJs.onData;
          var $container = data.error ? $error: $success;
          try{
            f.apply(widgetJs, [$container, data]);
          }
          catch (e) {
            atlas.logError(widgetJs, e);
          }

          // save timestamp
          $widget.attr('last-update', new Date().getTime());

          if (!data.error && !widgetJs.config) { // fill config when first data arrives
            widgetJs.config = data.config;
            setInterval(function() {
              atlas.checkElapsed($widget, widgetJs.config);
            }, 5000);
          }
        });

        io.emit('resend', widgetId);
        console.log('Sending resend for ' + widgetId);
      });
    });
  }
});

$(function() {
  atlas.$main = $('#main');
  atlas.$widgets = $('#widgets');
  atlas.$gridster = $('> ul', atlas.$widgets);

  if (!atlas.$widgets.length) return;

  var gutter = parseInt(atlas.$main.css('paddingTop'), 10) * 2,
      widgetMargin = gutter/2;
      width = atlas.$main.width() - gutter,
      height = atlas.$main.height() - gutter,
      cols = _.max(_.map(atlas.config.layout.widgets, function(widget) {
        return widget.col + widget.width - 1;
      })),
      rows = _.max(_.map(atlas.config.layout.widgets, function(widget) {
        return widget.row + widget.height - 1;
      })),
      widgetWidth = (width - cols * gutter) / cols,
      widgetHeight = (height - rows * gutter) / rows;

  atlas.$gridster.gridster({
    widget_margins: [
      widgetMargin,
      widgetMargin
    ],
    widget_base_dimensions: [
      widgetWidth,
      widgetHeight
    ],
    resize: {
      enabled: true,
      max_size: [cols, rows],
      min_size: [1, 1]
    }
  }).data('gridster');

  atlas.$main.css('height', atlas.$main.height() + 'px');
  // $(window.document.body).css('width', atlas.$main.width() + widgetWidth + 'px');
  $(window.document.body).css('height', atlas.$main.height() + widgetHeight + 'px');

  $(window).resize(_.throttle(function(){
    location.reload();
  }, 1000));
});
