(function() {

  $(function() {
    var socket;
    socket = io.connect('http://local.host');
    socket.on('distribute', function(data) {
      var channel, datachannel;
      channel = $('#' + data.channel);
      if (channel.length) {
        $('#' + data.channel + ' .results').append('<tr><td class="timestamp">' + new Date().toShortTimeString() + '</td><td class="from">' + data.from + '</td><td>' + data.message + '</td></tr>');
        datachannel = $('#' + data.channel);
        return datachannel.animate({
          scrollTop: datachannel[0].scrollHeight
        }, 1000);
      }
    });
    socket.on('channels', function(data) {
      var channel, channel_div, _i, _len, _ref;
      _ref = data.channels;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        channel = _ref[_i];
        channel_div = $('#' + channel);
        if (!channel_div.length) {
          $('#channels').append('<li><a href="#' + channel + '" id="tab-' + channel + '" data-toggle="tab">' + channel + '</a></li>');
          $('#screens').append('<div class="tab-pane" id="' + channel + '"><table class="results table-contensed table-bordered"></table></form></div>');
        }
      }
      $('#channels a:last').tab('show');
      if (data.channels.length) return $('#say').removeClass("hide");
    });
    $('#say').on('submit', function(e) {
      var active, channel, datachannel, message, user;
      e.preventDefault & e.preventDefault();
      user = "you";
      message = $('#message').val();
      $('#message').val("");
      active = $('#screens div.active');
      channel = active.attr('id');
      socket.emit('say', {
        message: message,
        channel: channel
      });
      $("#" + channel + ' .results').append('<tr class="originator"><td class="timestamp">' + new Date().toShortTimeString() + '</td><td class="from">' + user + '</td><td>' + message + '</td></tr>');
      datachannel = $('#' + channel);
      return datachannel.animate({
        scrollTop: datachannel[0].scrollHeight
      }, 1000);
    });
    return $('#channeljoin').on('click', function(e) {
      var channel;
      e.preventDefault & e.preventDefault();
      channel = $('#joinchannel').val();
      $('#joinchannel').val("");
      if (!$('#' + channel).length) {
        $('#channels').append('<li><a href="#' + channel + '" id="tab-' + channel + '" data-toggle="tab">' + channel + '</a></li>');
        $('#screens').append('<div class="tab-pane" id="' + channel + '"><table class="results table-contensed table-bordered"></table></form></div>');
        $('#tab-' + channel).tab('show');
        socket.emit('joinchannel', {
          channel: channel
        });
        return $('#say').removeClass("hide");
      } else {
        return $('#tab-' + channel).tab('show');
      }
    });
  });

}).call(this);
