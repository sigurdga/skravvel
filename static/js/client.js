(function() {

  $(function() {
    var socket;
    socket = io.connect('http://local.host');
    socket.on('distribute', function(data) {
      var channel, results;
      channel = $('#' + data.channel);
      if (channel.length) {
        $('#' + data.channel + ' .results').append('<div>' + data.from + ': ' + data.message + '</div>');
        results = $('#' + data.channel + ' .results');
        return results.animate({
          scrollTop: results[0].scrollHeight
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
          $('#screens').append('<div class="tab-pane" id="' + channel + '"><div class="results"></div></form></div>');
        }
      }
      $('#channels a:last').tab('show');
      if (data.channels.length) return $('#say').removeClass("hide");
    });
    $('#say').on('submit', function(e) {
      var active, channel, message, user;
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
      return $("#" + channel + ' .results').append('<div>' + user + ': ' + message + '</div>');
    });
    return $('#channeljoin').on('click', function(e) {
      var channel;
      e.preventDefault & e.preventDefault();
      channel = $('#joinchannel').val();
      $('#joinchannel').val("");
      if (!$('#' + channel).length) {
        $('#channels').append('<li><a href="#' + channel + '" id="tab-' + channel + '" data-toggle="tab">' + channel + '</a></li>');
        $('#screens').append('<div class="tab-pane" id="' + channel + '"><div class="results"></div></form></div>');
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
