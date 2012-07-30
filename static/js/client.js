(function() {

  $(function() {
    var socket;
    socket = io.connect('http://local.host');
    socket.on('distribute', function(data) {
      return $('#results').append('<div>' + data.from + '@' + data.channel + ': ' + data.message + '</div>');
    });
    $('#channel').on('submit', function(e) {
      var message;
      e.preventDefault & e.preventDefault();
      message = $('#message').val();
      socket.emit('send', {
        message: message,
        channel: 'strekmann'
      });
      return $('#results').append('<div>you@here: ' + message + '</div>');
    });
    return $('#modal-send').on('click', function(e) {
      var channel;
      e.preventDefault & e.preventDefault();
      channel = $('#joinchannel').val();
      $('#joinchannel').val("");
      return socket.emit('join', {
        channel: channel
      });
    });
  });

}).call(this);
